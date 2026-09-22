import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mysues/l10n/l10n.dart';

import '../models/academic_extract.dart';
import '../models/exam.dart';
import '../services/academic_import_snapshot.dart';
import '../services/exam_service.dart';
import '../services/schedule_service.dart';
import '../services/score_service.dart';
import '../services/webvpn/fetch_course_service.dart';
import '../services/webvpn/fetch_exam_service.dart';
import '../services/webvpn/fetch_info_service.dart';
import '../services/webvpn/fetch_score_service.dart';
import '../utils/course_conflict_util.dart';
import '../widgets/academic_extract_dialog.dart';

class LoginWebviewScreen extends StatefulWidget {
  const LoginWebviewScreen({super.key});

  @override
  State<LoginWebviewScreen> createState() => _LoginWebviewScreenState();
}

class _LoginWebviewScreenState extends State<LoginWebviewScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _isDataChanged = false;
  bool _isExtractRunning = false;

  String _currentStep = '';

  // URLs
  static const String initialUrl = 'https://webvpn.sues.edu.cn/login';

  // Known Academic System Hex ID for SUES WebVPN
  // Decoded from: https://webvpn.sues.edu.cn/...203b -> jxfw.sues.edu.cn
  static const String _academicHex =
      '77726476706e69737468656265737421faef478b69237d556d468ca88d1b203b';

  static const String _defaultVpnBase =
      'https://webvpn.sues.edu.cn/https/$_academicHex';

  // Dynamic base URL detected from user navigation
  String? _detectedVpnBase;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentStep.isEmpty) {
      _currentStep = context.l10n.signInToTheAcademicSystem;
    }
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // ..setUserAgent("...") // Use system default UserAgent to avoid compatibility issues
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Allow all navigations
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
              _detectBaseUrl(url);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _detectBaseUrl(url);
              _checkPageContent();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              "Web error: ${error.description}, Code: ${error.errorCode}",
            );
            // Handle ERR_CACHE_MISS (Avoid infinite reload loop)
            if (error.description.contains("CACHE_MISS")) {
              debugPrint(
                "Encountered ERR_CACHE_MISS. Suggest user to go back or refresh manually.",
              );
              // Do NOT auto reload here as it causes infinite loops if the POST data is gone.
            }
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );

    // Clear cache to resolve persistent ERR_CACHE_MISS
    await _controller.clearCache();
    await _controller.clearLocalStorage();

    if (mounted) {
      _controller.loadRequest(Uri.parse(initialUrl));
    }
  }

  // Auto-detect the correct proxy info from URL
  void _detectBaseUrl(String url) {
    debugPrint("Checking URL: $url");
    final uri = Uri.parse(url);
    if (uri.host == 'webvpn.sues.edu.cn') {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'https') {
        final hexKey = segments[1];
        // Supports both keys e.g. /https/HEX/eams or /https/HEX/student
        final newBase = "https://webvpn.sues.edu.cn/https/$hexKey";
        if (_detectedVpnBase != newBase) {
          _detectedVpnBase = newBase;
          debugPrint("Detected VPN Base: $_detectedVpnBase");
        }
      }
    }
  }

  Future<void> _checkPageContent() async {
    final String? url = await _controller.currentUrl();
    if (url != null &&
        (url.contains("/student/home") ||
            url.contains("/student/for-std/course-table"))) {
      // Only update UI text, do NOT auto start fetch
      setState(
        () => _currentStep =
            context.l10n.signedInUseTheButtonsBelowToRetrieveYour,
      );
    } else {
      final String? title = await _controller.getTitle();
      if (title != null) {
        if (title.contains("登录") || title.contains("Login")) {
          setState(() => _currentStep = context.l10n.signInToYourAccount);
        }
      }
    }
  }

  // --- One-tap extraction -------------------------------------------------

  /// Runs the ticked extraction tasks in the canonical order
  /// (schedule → scores → profile → exams), showing a checklist dialog.
  Future<void> _startExtract(Set<ExtractTask> tasks) async {
    if (_isExtractRunning || tasks.isEmpty) return;
    _isExtractRunning = true;

    try {
      final snapshot = await AcademicImportSnapshot.capture();
      if (!mounted) return;
      final orderedTasks =
          ExtractTask.values.where(tasks.contains).toList(growable: false);
      final targetBase = _detectedVpnBase ?? _defaultVpnBase;

      // Importing only the schedule keeps the semester picker so an older
      // semester can still be imported. Combined runs always use the latest
      // semester to stay truly one-tap.
      Map<String, dynamic>? fixedSemester;
      if (orderedTasks.length == 1 &&
          orderedTasks.first == ExtractTask.schedule) {
        fixedSemester = await _pickSemesterForImport(targetBase);
        if (fixedSemester == null || !mounted) return;
      }

      final state = ValueNotifier<ExtractDialogState>(
        ExtractDialogState(
          progress: orderedTasks
              .map((task) => ExtractTaskProgress(task: task))
              .toList(),
          statusText: context.l10n.extractPreparing,
        ),
      );

      var cancelRequested = false;
      var actionCompleter = Completer<bool>();
      BuildContext? dialogContext;

      final dialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return AcademicExtractDialog(
            state: state,
            onCancel: () {
              cancelRequested = true;
              state.value = state.value.copyWith(
                statusText: context.l10n.extractCancelling,
              );
            },
            onRetryFailed: () => _completeAction(actionCompleter, true),
            onDone: () => _completeAction(actionCompleter, false),
          );
        },
      );
      // Closing the dialog by any other means (e.g. the back gesture on the
      // summary) behaves exactly like tapping "done".
      dialogFuture.whenComplete(() => _completeAction(actionCompleter, false));

      var conflictCount = 0;
      var anySuccess = false;

      while (true) {
        await _runPendingSteps(
          state,
          targetBase: targetBase,
          fixedSemester: fixedSemester,
          isCancelled: () => cancelRequested,
          onSuccess: (outcome) {
            anySuccess = true;
            conflictCount += outcome.conflictCount;
          },
        );

        if (cancelRequested) break;

        state.value = state.value.copyWith(
          finished: true,
          conflictCount: conflictCount,
          clearStatusText: true,
        );

        final retry = await actionCompleter.future;
        if (!retry) break;
        if (!mounted) break;

        actionCompleter = Completer<bool>();
        state.value = state.value.copyWith(
          finished: false,
          statusText: context.l10n.extractPreparing,
          progress: state.value.progress
              .map(
                (item) =>
                    item.status == ExtractTaskStatus.failure ||
                        item.status == ExtractTaskStatus.cancelled
                    ? item.copyWith(
                        status: ExtractTaskStatus.pending,
                        clearDetail: true,
                      )
                    : item,
              )
              .toList(),
        );
      }

      if (cancelRequested) {
        try {
          await snapshot.restore();
        } catch (e) {
          debugPrint('Failed to roll back the cancelled extraction: $e');
        }
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      await dialogFuture;

      if (!mounted) return;

      if (cancelRequested) {
        _showSnack(context.l10n.extractCancelledRolledBack);
        return;
      }

      // Nothing was stored, so there is no reason to leave the page.
      if (!anySuccess) return;

      _isDataChanged = true;
      await _recordSyncTime();
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      _isExtractRunning = false;
    }
  }

  Future<void> _runPendingSteps(
    ValueNotifier<ExtractDialogState> state, {
    required String targetBase,
    required Map<String, dynamic>? fixedSemester,
    required bool Function() isCancelled,
    required void Function(_StepOutcome outcome) onSuccess,
  }) async {
    final pending = state.value.progress
        .where((item) => item.status == ExtractTaskStatus.pending)
        .map((item) => item.task)
        .toList();
    if (pending.isEmpty) return;

    if (isCancelled()) {
      for (final task in pending) {
        _setTaskState(state, task, ExtractTaskStatus.cancelled);
      }
      return;
    }

    final session = await _prepareSession(
      targetBase,
      fixedSemester: fixedSemester,
      isCancelled: isCancelled,
    );
    if (!mounted) return;

    if (isCancelled()) {
      for (final task in pending) {
        _setTaskState(state, task, ExtractTaskStatus.cancelled);
      }
      return;
    }

    if (session == null) {
      final message = context.l10n.extractNotSignedIn;
      for (final task in pending) {
        _setTaskState(state, task, ExtractTaskStatus.failure, detail: message);
      }
      return;
    }

    for (final task in pending) {
      if (isCancelled()) {
        _setTaskState(state, task, ExtractTaskStatus.cancelled);
        continue;
      }

      _setTaskState(state, task, ExtractTaskStatus.running);
      final outcome = await _runExtractTask(task, session);
      if (!mounted) return;

      _setTaskState(
        state,
        task,
        outcome.success ? ExtractTaskStatus.success : ExtractTaskStatus.failure,
        detail: outcome.success ? outcome.detail : outcome.error,
      );
      if (outcome.success) onSuccess(outcome);
    }
  }

  void _setTaskState(
    ValueNotifier<ExtractDialogState> state,
    ExtractTask task,
    ExtractTaskStatus status, {
    String? detail,
  }) {
    final progress = state.value.progress
        .map(
          (item) => item.task == task
              ? item.copyWith(
                  status: status,
                  detail: detail,
                  clearDetail: detail == null,
                )
              : item,
        )
        .toList();

    final runningText =
        '${_taskTitle(context, task)} · ${context.l10n.extractStatusRunning}';
    final statusText = status == ExtractTaskStatus.running
        ? runningText
        : state.value.statusText;

    state.value = state.value.copyWith(
      progress: progress,
      statusText: statusText,
    );

    if (status == ExtractTaskStatus.running) {
      _updateStep(runningText);
    }
  }

  /// Ensures the WebView sits on the course table page so XHR requests share
  /// the academic system session.
  Future<void> _ensureCourseTablePage(
    String targetBase, {
    bool Function()? isCancelled,
  }) async {
    final l10n = context.l10n;
    final currentUrl = await _controller.currentUrl();
    if (currentUrl != null &&
        currentUrl.contains('student/for-std/course-table')) {
      return;
    }

    _updateStep(l10n.openingTheSchedulePage);
    await _controller.loadRequest(
      Uri.parse('$targetBase/student/for-std/course-table'),
    );

    for (var retry = 0; retry < 15; retry++) {
      await Future.delayed(const Duration(seconds: 1));
      if (isCancelled?.call() ?? false) return;
      final url = await _controller.currentUrl();
      if (url != null && url.contains('course-table')) return;
    }
  }

  Future<List<String>> _fetchSemesterIdsWithRetry({
    int attempts = 15,
    bool Function()? isCancelled,
  }) async {
    var semesterIds = <String>[];
    for (var attempt = 0; attempt < attempts; attempt++) {
      semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
      if (semesterIds.isNotEmpty) break;
      if (isCancelled?.call() ?? false) break;
      await Future.delayed(const Duration(seconds: 1));
      if (isCancelled?.call() ?? false) break;
    }
    return semesterIds;
  }

  Future<_AcademicSession?> _prepareSession(
    String targetBase, {
    Map<String, dynamic>? fixedSemester,
    bool Function()? isCancelled,
  }) async {
    final l10n = context.l10n;

    _updateStep(l10n.retrievingSemesters);
    await _ensureCourseTablePage(targetBase, isCancelled: isCancelled);
    if (isCancelled?.call() ?? false) return null;
    if (!mounted) return null;

    final semesterIds = await _fetchSemesterIdsWithRetry(
      isCancelled: isCancelled,
    );
    if (semesterIds.isEmpty) return null;
    if (isCancelled?.call() ?? false) return null;

    if (fixedSemester != null) {
      return _AcademicSession(
        baseUrl: targetBase,
        semesterIds: semesterIds,
        semesterId: fixedSemester['id'] as String,
        semesterName: fixedSemester['name'] as String,
        startDate: (fixedSemester['startDate'] as String?) ?? '2024-09-01',
      );
    }

    final latestSemesterId = _pickLatestSemesterId(semesterIds);
    final info = await FetchCourseService.fetchSemesterInfo(
      _controller,
      targetBase,
      latestSemesterId,
    );
    final name = info?['nameZh']?.toString();

    return _AcademicSession(
      baseUrl: targetBase,
      semesterIds: semesterIds,
      semesterId: latestSemesterId,
      semesterName: (name == null || name.isEmpty)
          ? l10n.semesterFallbackName(latestSemesterId)
          : name,
      startDate: info?['startDate']?.toString() ?? '2024-09-01',
    );
  }

  /// Picks the newest semester: the biggest numeric id, falling back to the
  /// first option of the page selector when ids are not numeric.
  static String _pickLatestSemesterId(List<String> semesterIds) {
    final numericIds = semesterIds.map(int.tryParse).toList();
    if (numericIds.any((id) => id == null)) return semesterIds.first;

    var latestIndex = 0;
    for (var index = 1; index < numericIds.length; index++) {
      if (numericIds[index]! > numericIds[latestIndex]!) {
        latestIndex = index;
      }
    }
    return semesterIds[latestIndex];
  }

  /// Lets the user pick any semester, with the latest one on top. Only used
  /// when the schedule is the single ticked item.
  Future<Map<String, dynamic>?> _pickSemesterForImport(
    String targetBase,
  ) async {
    final l10n = context.l10n;

    await _ensureCourseTablePage(targetBase);
    if (!mounted) return null;

    final semesterIds = await _fetchSemesterIdsWithRetry();
    if (!mounted) return null;
    if (semesterIds.isEmpty) {
      _showSnack(l10n.unableToRetrieveSemestersTryAgain);
      return null;
    }

    _updateStep(l10n.parsingSemesterInformation(semesterIds.length));

    final options = <Map<String, dynamic>>[];
    for (final id in semesterIds) {
      final info = await FetchCourseService.fetchSemesterInfo(
        _controller,
        targetBase,
        id,
      );
      if (!mounted) return null;
      final name = info?['nameZh']?.toString();
      options.add({
        'id': id,
        'name': (name == null || name.isEmpty)
            ? l10n.semesterFallbackName(id)
            : name,
        'startDate': info?['startDate']?.toString() ?? '2024-09-01',
      });
    }

    final latestSemesterId = _pickLatestSemesterId(semesterIds);
    final latestIndex = options.indexWhere(
      (option) => option['id'] == latestSemesterId,
    );
    if (latestIndex > 0) {
      options.insert(0, options.removeAt(latestIndex));
    }

    if (!mounted) return null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.chooseASemesterToImport),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (ctx, index) {
              final item = options[index];
              final isLatest = item['id'] == latestSemesterId;
              return ListTile(
                selected: isLatest,
                title: Text(item['name'] as String),
                subtitle: Text('ID: ${item['id']}'),
                trailing: isLatest ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<_StepOutcome> _runExtractTask(
    ExtractTask task,
    _AcademicSession session,
  ) async {
    try {
      return switch (task) {
        ExtractTask.schedule => await _runScheduleStep(session),
        ExtractTask.scores => await _runScoresStep(session),
        ExtractTask.profile => await _runProfileStep(session),
        ExtractTask.exams => await _runExamsStep(session),
      };
    } catch (e) {
      debugPrint('Extract $task failed: $e');
      if (!mounted) return _StepOutcome.failure('$e');
      return _StepOutcome.failure(context.l10n.extractionFailedWithError('$e'));
    }
  }

  Future<_StepOutcome> _runScheduleStep(_AcademicSession session) async {
    final l10n = context.l10n;
    final courseData = await FetchCourseService.fetchCourseData(
      _controller,
      session.baseUrl,
      session.semesterId,
    );
    if (!mounted) return _StepOutcome.failure('');
    if (courseData == null) {
      return _StepOutcome.failure(l10n.failedToRetrieveScheduleData);
    }

    final courses = FetchCourseService.parseCourseData(courseData, 0);
    final catalog = FetchCourseService.parseCourseCatalog(
      courseData,
      0,
      session.semesterName,
    );
    if (courses.isEmpty && catalog.courses.isEmpty) {
      return _StepOutcome.failure(l10n.noCoursesCouldBeParsed);
    }

    // The course table payload also carries the internal student id needed by
    // the score and exam endpoints, so cache it for the following steps.
    session.internalStudentId =
        await _cacheStudentIdentity(courseData) ?? session.internalStudentId;

    final table = await ScheduleDataService.upsertScheduleTable(
      semesterName: session.semesterName,
      startDate: session.startDate,
    );
    await ScheduleDataService.replaceCoursesForTable(
      tableId: table.id,
      courses: courses,
      catalog: catalog,
    );

    return _StepOutcome.success(
      l10n.extractResultSchedule(courses.length),
      conflictCount: CourseConflictUtil.getConflictGroups(courses).length,
    );
  }

  Future<_StepOutcome> _runScoresStep(_AcademicSession session) async {
    final l10n = context.l10n;
    final studentId = await _resolveInternalStudentId(session);
    if (!mounted) return _StepOutcome.failure('');
    if (studentId == null) {
      return _StepOutcome.failure(l10n.unableToParseTheScheduleData);
    }

    final scores = await FetchScoreService.fetchAllScores(
      _controller,
      session.baseUrl,
      studentId,
      session.semesterIds,
    );
    if (!mounted) return _StepOutcome.failure('');
    if (scores.isEmpty) {
      return _StepOutcome.failure(
        l10n.noScoresForSemesters(session.semesterIds.length),
      );
    }

    await ScoreService.saveScores(scores);
    await ScoreService.saveLastImportTime(_timestamp());
    if (!mounted) return _StepOutcome.failure('');
    return _StepOutcome.success(l10n.extractResultScores(scores.length));
  }

  Future<_StepOutcome> _runProfileStep(_AcademicSession session) async {
    final l10n = context.l10n;
    final info = await FetchInfoService.fetchStudentInfo(
      _controller,
      session.baseUrl,
    );
    if (!mounted) return _StepOutcome.failure('');
    if (info == null || (info['name'] ?? '').isEmpty) {
      return _StepOutcome.failure(
        l10n.noValidProfileInformationCouldBeExtracted,
      );
    }

    await FetchInfoService.saveStudentInfo(info);
    if ((info['id'] ?? '').isNotEmpty) {
      session.internalStudentId = info['id'];
    }
    if (!mounted) return _StepOutcome.failure('');
    return _StepOutcome.success(l10n.extractResultProfile);
  }

  Future<_StepOutcome> _runExamsStep(_AcademicSession session) async {
    final l10n = context.l10n;
    final studentId = await _resolveInternalStudentId(session);
    if (!mounted) return _StepOutcome.failure('');
    if (studentId == null || studentId.isEmpty) {
      return _StepOutcome.failure(
        l10n.unableToRetrieveStudentInformationTryAgain,
      );
    }

    // iOS WKWebView may need a moment before the session cookie is available
    // for the exam endpoint, so retry a couple of times.
    var exams = <Exam>[];
    for (var attempt = 1; attempt <= 3; attempt++) {
      exams = await FetchExamService.fetchExams(
        _controller,
        session.baseUrl,
        studentId: studentId,
      );
      if (exams.isNotEmpty) break;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted) return _StepOutcome.failure('');
    if (exams.isEmpty) {
      return _StepOutcome.failure(l10n.noExamDataWasFound);
    }

    await ExamService.saveExams(exams);
    if (!mounted) return _StepOutcome.failure('');
    return _StepOutcome.success(l10n.extractResultExams(exams.length));
  }

  Future<String?> _resolveInternalStudentId(_AcademicSession session) async {
    if (session.internalStudentId != null) return session.internalStudentId;

    final courseData = await FetchCourseService.fetchCourseData(
      _controller,
      session.baseUrl,
      session.semesterId,
    );
    if (courseData == null) return null;

    session.internalStudentId = await _cacheStudentIdentity(courseData);
    return session.internalStudentId;
  }

  Future<String?> _cacheStudentIdentity(Map<String, dynamic> courseData) async {
    final vms = courseData['studentTableVms'];
    if (vms is! List || vms.isEmpty || vms.first is! Map) return null;

    final vm = Map<String, dynamic>.from(vms.first as Map);
    final internalId = vm['id']?.toString();
    if (internalId == null || internalId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_internal_id', internalId);
    if (vm['code'] != null) {
      await prefs.setString('student_id', vm['code'].toString());
    }
    if (vm['name'] != null) {
      await prefs.setString('user_nickname', vm['name'].toString());
    }
    return internalId;
  }

  void _showExtractSheet() {
    final selected = ExtractTask.values.toSet();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                context.l10n.chooseTheDataToRetrieve,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              for (final task in ExtractTask.values)
                CheckboxListTile(
                  value: selected.contains(task),
                  onChanged: (value) => setSheetState(() {
                    if (value == true) {
                      selected.add(task);
                    } else {
                      selected.remove(task);
                    }
                  }),
                  secondary: Icon(_taskIcon(task)),
                  title: Text(_taskTitle(context, task)),
                  controlAffinity: ListTileControlAffinity.trailing,
                  dense: true,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            final tasks = Set<ExtractTask>.of(selected);
                            Navigator.pop(sheetContext);
                            _startExtract(tasks);
                          },
                    icon: const Icon(Icons.download_done),
                    label: Text(context.l10n.oneTapExtract),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _taskIcon(ExtractTask task) {
    return switch (task) {
      ExtractTask.schedule => Icons.calendar_month,
      ExtractTask.scores => Icons.score,
      ExtractTask.profile => Icons.person,
      ExtractTask.exams => Icons.assignment,
    };
  }

  String _taskTitle(BuildContext context, ExtractTask task) {
    final l10n = context.l10n;
    return switch (task) {
      ExtractTask.schedule => l10n.extractTaskSchedule,
      ExtractTask.scores => l10n.extractTaskScores,
      ExtractTask.profile => l10n.extractTaskProfile,
      ExtractTask.exams => l10n.extractTaskExams,
    };
  }

  void _completeAction(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}"
        "-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}"
        ":${now.minute.toString().padLeft(2, '0')}";
  }

  void _updateStep(String step) {
    if (!mounted) return;
    setState(() => _currentStep = step);
  }

  Future<void> _recordSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_sync_time_academic',
      DateTime.now().toString().substring(0, 16),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isDataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.webVpnDataImport),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.clearCache,
              onPressed: () async {
                await _controller.clearCache();
                await _controller.clearLocalStorage();
                if (mounted) _showSnack(context.l10n.cacheCleared);
                _controller.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _controller.loadRequest(Uri.parse(initialUrl)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _currentStep,
                style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                onPressed: _showExtractSheet,
                icon: const Icon(Icons.download_done, size: 18),
                label: Text(context.l10n.extract),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Session context shared by all extraction steps of a single run.
class _AcademicSession {
  _AcademicSession({
    required this.baseUrl,
    required this.semesterIds,
    required this.semesterId,
    required this.semesterName,
    required this.startDate,
  });

  final String baseUrl;
  final List<String> semesterIds;
  final String semesterId;
  final String semesterName;
  final String startDate;

  /// Internal student id (not the student number), resolved lazily.
  String? internalStudentId;
}

/// Result of a single extraction step.
class _StepOutcome {
  const _StepOutcome.success(this.detail, {this.conflictCount = 0})
    : success = true,
      error = null;

  const _StepOutcome.failure(this.error)
    : success = false,
      detail = null,
      conflictCount = 0;

  final bool success;
  final String? detail;
  final String? error;
  final int conflictCount;
}
