import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/networking/academic_client.dart';
import '../services/webvpn/fetch_course_service.dart';
import '../services/webvpn/fetch_info_service.dart';
import '../services/webvpn/fetch_score_service.dart';
import '../services/webvpn/fetch_exam_service.dart';
import '../models/exam.dart';
import '../services/parsers/student_info_parser.dart';
import '../models/schedule_table.dart';
import '../services/schedule_service.dart';
import '../services/score_service.dart';
import '../services/exam_service.dart';
import '../utils/course_conflict_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/l10n/localized_formatters.dart';

class LoginWebviewScreen extends StatefulWidget {
  const LoginWebviewScreen({super.key});

  @override
  State<LoginWebviewScreen> createState() => _LoginWebviewScreenState();
}

class _LoginWebviewScreenState extends State<LoginWebviewScreen> {
  late final WebViewController _controller;
  final AcademicClient _academicClient = AcademicClient();

  bool _isLoading = true;
  bool _hasStartedAutoFetch = false;
  bool _isDataChanged = false;
  // 区分当前是“抓取课表”还是“抓取个人信息”
  bool _isFetchingInfo = false;

  String _currentStep = '';

  // URLs
  static const String initialUrl = 'https://webvpn.sues.edu.cn/login';

  // Known Academic System Hex ID for SUES WebVPN
  // Decoded from: https://webvpn.sues.edu.cn/...203b -> jxfw.sues.edu.cn
  static const String _academicHex =
      '77726476706e69737468656265737421faef478b69237d556d468ca88d1b203b';

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

  Future<String> _getCookieString() async {
    // Only use document.cookie which is available via JS
    // Note: This misses HttpOnly cookies, so for API calls that require session,
    // we should use _fetchWithXhr to execute requests inside the WebView context.
    try {
      final String result =
          await _controller.runJavaScriptReturningResult('document.cookie')
              as String;
      return _decodeJsString(result);
    } catch (e) {
      return "";
    }
  }

  Future<void> _startAutoFetch() async {
    // Prevent multiple triggers
    if (_hasStartedAutoFetch) return;
    _hasStartedAutoFetch = true;

    try {
      String targetBase =
          _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";

      // 1. Navigate to course table page if not there
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null ||
          !currentUrl.contains("student/for-std/course-table")) {
        setState(() => _currentStep = context.l10n.openingTheSchedulePage);
        final courseUrl = "$targetBase/student/for-std/course-table";
        await _controller.loadRequest(Uri.parse(courseUrl));

        // Wait for page load (simple delay loop)
        int retries = 0;
        while (retries < 10) {
          await Future.delayed(const Duration(seconds: 1));
          final url = await _controller.currentUrl();
          if (url != null && url.contains("course-table")) break;
          retries++;
        }
      }

      setState(() => _currentStep = context.l10n.retrievingSemesters);

      // 2. Wait for semester selector (handled by repeated fetch attempts)
      List<String> semesterIds = [];
      int retryCount = 0;
      while (retryCount < 15) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(seconds: 1));
        retryCount++;
      }

      if (semesterIds.isEmpty) {
        _showSnack(context.l10n.noSemesterListWasFoundTryAgain);
        setState(() {
          _currentStep = context.l10n.requestFailedTryAgain;
          _hasStartedAutoFetch = false; // Allow retry
        });
        return;
      }

      // 3. Branch logic based on user intent
      // Fetch Info OR Fetch Schedule
      if (_isFetchingInfo) {
        // --- Auto Fetch Info Logic ---
        setState(() => _currentStep = context.l10n.retrievingProfile);
        final info = await FetchInfoService.fetchStudentInfo(
          _controller,
          targetBase,
        );

        if (info != null && info.isNotEmpty) {
          await FetchInfoService.saveStudentInfo(info);
          if (!mounted) return;
          final code = info['code'] == null ? '' : ' (${info['code']})';
          final msg = context.l10n.updatedProfile(
            info['name']?.toString() ?? '',
            code,
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          _recordSyncTime();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.noValidProfileInformationCouldBeExtracted,
              ),
            ),
          );
        }

        // Cleanup & Exit
        // await _controller.clearCache();
        // await _controller.clearLocalStorage();
        // final cookieManager = WebViewCookieManager();
        // await cookieManager.clearCookies();
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      // --- END Info Logic ---

      if (!mounted) return;

      // Fetch details for display (nameZh) - Optional, mimicking python
      // Python: build_semester_list -> fetches info for EACH id.
      // This might be slow if many IDs. Python does it. I will do it.
      setState(
        () => _currentStep = context.l10n.parsingSemesterInformation(
          semesterIds.length,
        ),
      );

      List<Map<String, dynamic>> semesterOptions = [];
      for (var id in semesterIds) {
        final info = await FetchCourseService.fetchSemesterInfo(
          _controller,
          targetBase,
          id,
        );
        if (info != null) {
          semesterOptions.add({
            'id': id,
            'name': info['nameZh'] ?? context.l10n.unknownSemester,
            'info': info,
          });
        } else {
          semesterOptions.add({
            'id': id,
            'name': context.l10n.semesterFallbackName(id),
            'info': {},
          });
        }
      }

      if (!mounted) return;

      final selectedMap = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.chooseASemesterToImport),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: semesterOptions.length,
              itemBuilder: (ctx, index) {
                final item = semesterOptions[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text("ID: ${item['id']}"),
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

      if (selectedMap == null) {
        setState(() {
          _currentStep = context.l10n.operationCancelled;
          _hasStartedAutoFetch = false;
        });
        return;
      }

      final semesterId = selectedMap['id'] as String;
      final info = selectedMap['info'] as Map<String, dynamic>;
      final semesterName = selectedMap['name'] as String;

      setState(
        () =>
            _currentStep = context.l10n.fetchingSemesterSchedule(semesterName),
      );

      // 4. Fetch Course Data
      final courseData = await FetchCourseService.fetchCourseData(
        _controller,
        targetBase,
        semesterId,
      );
      if (courseData == null) {
        _showSnack(context.l10n.failedToRetrieveScheduleData);
        setState(() => _hasStartedAutoFetch = false);
        return;
      }

      // 5. Prepare the schedule table and both kinds of course data. The table
      // is not persisted until the user accepts any conflict warning.
      final startDateStr = info['startDate'] as String? ?? "2024-09-01";
      final table = ScheduleTable(
        tableName: semesterName,
        nodes: 15,
        startDate: startDateStr,
      );

      setState(() => _currentStep = context.l10n.savingCourseData);
      final courses = FetchCourseService.parseCourseData(courseData, 0);
      var courseCatalog = FetchCourseService.parseCourseCatalog(
        courseData,
        0,
        semesterName,
      );

      if (courses.isEmpty && courseCatalog.courses.isEmpty) {
        _showSnack(context.l10n.noCoursesCouldBeParsed);
        setState(() => _hasStartedAutoFetch = false);
        return;
      } else {
        // Detect conflicts
        bool saveAgreed = true;
        var conflictGroups = CourseConflictUtil.getConflictGroups(courses);
        if (conflictGroups.isNotEmpty && mounted) {
          saveAgreed =
              await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text(context.l10n.warningCourseConflict),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.theFollowingCoursesOverlap),
                          const SizedBox(height: 8),
                          ...conflictGroups.values.map((group) {
                            final names = group
                                .map((course) {
                                  final schedule = context.l10n
                                      .courseScheduleLine(
                                        localizedWeekdayLabel(
                                          context.l10n,
                                          course.day,
                                        ),
                                        context.l10n.periodRange(
                                          course.startNode,
                                          course.startNode + course.step - 1,
                                        ),
                                        '',
                                      );
                                  return '• ${course.courseName} ($schedule)';
                                })
                                .join('\n');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                names,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.saveAnywayYouCanViewThemInTheSchedule,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(context.l10n.cancelImport),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(context.l10n.saveAnyway),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        }

        if (saveAgreed) {
          await ScheduleDataService.addScheduleTable(table);
          for (final course in courses) {
            course.tableId = table.id;
          }
          courseCatalog = courseCatalog.copyWith(tableId: table.id);

          final allCourses = await ScheduleDataService.loadCourses();
          int maxId = 0;
          if (allCourses.isNotEmpty) {
            maxId = allCourses.map((e) => e.id).reduce((a, b) => a > b ? a : b);
          }
          for (final course in courses) {
            course.id = ++maxId;
            allCourses.add(course);
          }

          await ScheduleDataService.saveCourses(allCourses);
          await ScheduleDataService.saveCourseCatalog(courseCatalog);
        } else {
          if (!mounted) return;
          final l10n = context.l10n;
          setState(() {
            _currentStep = l10n.operationCancelled;
            _hasStartedAutoFetch = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.importCancelled)));
          return;
        }

        // Set as current table
        await ScheduleDataService.setCurrentTableId(table.id);

        // 统计实际课程门数（去重）
        final uniqueCount = courseCatalog.courses.isNotEmpty
            ? courseCatalog.courses.length
            : courses.map((course) => course.courseName).toSet().length;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.importedCourses(uniqueCount, courses.length),
            ),
          ),
        );
        _recordSyncTime();

        // Cleanup: Clear WebView cache and cookies to protect privacy and ensure fresh state next time
        // await _controller.clearCache();
        // await _controller.clearLocalStorage();
        // final cookieManager = WebViewCookieManager();
        // await cookieManager.clearCookies();

        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      debugPrint("Auto fetch error: $e");
      if (mounted) _showSnack(context.l10n.genericErrorWithDetail('$e'));
      setState(() => _hasStartedAutoFetch = false);
    }
  }

  Future<void> _extractScore() async {
    try {
      String targetBase =
          _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";

      _showSnack(context.l10n.retrievingBasicData);

      // 1. Ensure we are on the course table page to get semester IDs
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null ||
          !currentUrl.contains("student/for-std/course-table")) {
        _showSnack(context.l10n.openingTheSchedulePageToRetrieveData);
        String courseUrl = "$targetBase/student/for-std/course-table";
        await _controller.loadRequest(Uri.parse(courseUrl));

        // Wait for page load
        int retries = 0;
        while (retries < 15) {
          await Future.delayed(const Duration(milliseconds: 1000));
          final url = await _controller.currentUrl();
          if (url != null && url.contains("course-table")) break;
          retries++;
        }
      }

      // 2. Fetch semester IDs (needed for both ID extraction and Score fetching)
      List<String> semesterIds = [];
      int retryCount = 0;
      while (retryCount < 10) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (semesterIds.isEmpty) {
        throw StateError(context.l10n.unableToRetrieveSemestersTryAgain);
      }

      // 3. Always parse Student ID from course data (ignoring local cache)
      String? studentId;
      _showSnack(context.l10n.parsing);

      // Use the first (usually latest) semester to fetch course table data which contains the ID
      final latestSemester = semesterIds.first;
      final courseData = await FetchCourseService.fetchCourseData(
        _controller,
        targetBase,
        latestSemester,
      );

      if (courseData != null && courseData['studentTableVms'] != null) {
        final vms = courseData['studentTableVms'] as List;
        if (vms.isNotEmpty) {
          final vm = vms[0];
          if (vm['id'] != null) {
            studentId = vm['id'].toString(); // 内部 ID，用于成绩查询等 API

            // Sync to cache for other uses
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_internal_id', studentId);
            // code 才是真正的学号
            if (vm['code'] != null) {
              await prefs.setString('student_id', vm['code'].toString());
            }
            if (vm['name'] != null) {
              await prefs.setString('user_nickname', vm['name'].toString());
            }
          }
        }
      }

      if (studentId == null) {
        throw StateError(context.l10n.unableToParseTheScheduleData);
      }

      _showSnack(context.l10n.retrievingScoresForSemesters(semesterIds.length));

      // 4. Fetch Scores
      final scores = await FetchScoreService.fetchAllScores(
        _controller,
        targetBase,
        studentId,
        semesterIds,
      );

      if (scores.isEmpty) {
        final msg = context.l10n.noScoresForSemesters(semesterIds.length);
        debugPrint(msg);
        _showSnack(msg);
        return;
      }

      await ScoreService.saveScores(scores);

      final now = DateTime.now();
      final timeStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await ScoreService.saveLastImportTime(timeStr);

      _showSnack(context.l10n.importedScoreRecords(scores.length));
      _isDataChanged = true;
      _recordSyncTime();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Extract score error: $e");
      _showSnack(context.l10n.extractionFailedWithError('$e'));
    }
  }

  void _updateStep(String step) {
    if (!mounted) return;
    setState(() => _currentStep = step);
  }

  Future<void> _extractExam() async {
    try {
      String targetBase =
          _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";

      // 1. 确保 WebView 已导航到课表页面（建立 session 上下文）
      final currentUrl = await _controller.currentUrl();
      if (!mounted) return;
      if (currentUrl == null ||
          !currentUrl.contains("student/for-std/course-table")) {
        _updateStep(context.l10n.openingTheAcademicSystem);
        String courseUrl = "$targetBase/student/for-std/course-table";
        await _controller.loadRequest(Uri.parse(courseUrl));
        if (!mounted) return;

        int retries = 0;
        while (retries < 15) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          final url = await _controller.currentUrl();
          if (!mounted) return;
          if (url != null && url.contains("course-table")) break;
          retries++;
        }
      }

      // 2. 等待学期列表加载完成（确认页面会话已就绪，最多30秒）
      _updateStep(context.l10n.waitingForThePageToLoad);
      List<String> semesterIds = [];
      int retryCount = 0;
      while (retryCount < 30) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (!mounted) return;
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        retryCount++;
      }

      if (semesterIds.isEmpty) {
        _showSnack(context.l10n.thePageIsNotReadyTryAgain);
        _updateStep(context.l10n.pageLoadingTimedOutTryAgain);
        return;
      }

      // 3. 从课表数据中提取 studentId（与成绩提取相同的可靠方式）
      _updateStep(context.l10n.parsingStudentInformation);
      String? studentId;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      studentId = prefs.getString('user_internal_id');

      if (studentId == null || studentId.isEmpty) {
        final latestSemester = semesterIds.first;
        final courseData = await FetchCourseService.fetchCourseData(
          _controller,
          targetBase,
          latestSemester,
        );
        if (!mounted) return;

        if (courseData != null && courseData['studentTableVms'] != null) {
          final vms = courseData['studentTableVms'] as List;
          if (vms.isNotEmpty) {
            final vm = vms[0];
            if (vm['id'] != null) {
              studentId = vm['id'].toString();
              await prefs.setString('user_internal_id', studentId);
              if (!mounted) return;
              if (vm['code'] != null) {
                await prefs.setString('student_id', vm['code'].toString());
                if (!mounted) return;
              }
              if (vm['name'] != null) {
                await prefs.setString('user_nickname', vm['name'].toString());
                if (!mounted) return;
              }
            }
          }
        }
      }

      if (studentId == null || studentId.isEmpty) {
        _showSnack(context.l10n.unableToRetrieveStudentInformationTryAgain);
        _updateStep(context.l10n.failedToRetrieveStudentInformation);
        return;
      }

      // 4. 提取考试数据（带重试，iOS WKWebView 首次 XHR 可能因 session cookie 延迟而失败）
      List<Exam> exams = [];
      for (int attempt = 1; attempt <= 3; attempt++) {
        _updateStep(
          attempt == 1
              ? context.l10n.retrievingExams
              : context.l10n.retrievingExamsAttempt(attempt),
        );
        exams = await FetchExamService.fetchExams(
          _controller,
          targetBase,
          studentId: studentId,
        );
        if (!mounted) return;
        if (exams.isNotEmpty) break;
        if (attempt < 3) {
          _updateStep(context.l10n.noDataReceivedWaitingToRetry);
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
        }
      }

      if (exams.isEmpty) {
        _showSnack(context.l10n.noExamDataWasFound);
        _updateStep(context.l10n.noExamDataWasFound2);
        return;
      }

      await ExamService.saveExams(exams);
      if (!mounted) return;

      _isDataChanged = true;
      await _recordSyncTime();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Extract Exam Error: $e");
      _showSnack(context.l10n.extractionFailedWithError('$e'));
      _updateStep(context.l10n.extractionFailedTryAgain);
    }
  }

  Future<void> _extractInfo() async {
    // Info is usually on the home page or specific page.
    // CourseAdapter might not have a dedicated info parser or uses one of the pages.
    // We'll try fetching the home page or student info page.
    try {
      String targetBase =
          _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";

      // Try fetching the user detail page or just header info from course page
      // Let's reuse course page as it usually contains student info in header
      final cookie = await _getCookieString();
      final html = await _academicClient.fetchHtmlWithCookie(
        "$targetBase/eams/courseTableForStd.action",
        cookie,
      );

      if (html == null) throw "Network Error";

      final parser = StudentInfoParser();
      final info = parser.parse(html);

      if (info.isEmpty || info['name'] == null) {
        _showSnack(context.l10n.noProfileInformationWasFound);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (info['name'] != null) {
        await prefs.setString('user_nickname', info['name']!);
      }
      if (info['studentId'] != null) {
        await prefs.setString('student_id', info['studentId']!);
      }
      if (info['major'] != null) {
        await prefs.setString('user_major', info['major']!);
      }
      if (info['college'] != null) {
        await prefs.setString('user_college', info['college']!);
      }

      final studentId = info['studentId'] == null
          ? ''
          : ' (${info['studentId']})';
      final msg = context.l10n.updatedProfileInformation(
        info['name'] ?? '',
        studentId,
      );
      _showSnack(msg);
      _recordSyncTime();
    } catch (e) {
      _showSnack(context.l10n.extractionFailedWithError('$e'));
    }
  }

  String _decodeJsString(String jsInfo) {
    try {
      // webview_flutter returns a JSON string representation
      return jsonDecode(jsInfo).toString();
    } catch (e) {
      debugPrint("JSON Decode error: $e");
      // Fallback manual decode if jsonDecode fails
      if (jsInfo.startsWith('"') && jsInfo.endsWith('"')) {
        return jsInfo
            .substring(1, jsInfo.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
      }
      return jsInfo;
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.chooseTheDataToRetrieve,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(context.l10n.retrieveProfile),
                            onTap: () {
                              Navigator.pop(context);
                              _isFetchingInfo = true;
                              _startAutoFetch();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: Text(context.l10n.retrieveSchedule),
                            onTap: () {
                              Navigator.pop(context);
                              _isFetchingInfo = false;
                              _startAutoFetch();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.score),
                            title: Text(context.l10n.retrieveGrades),
                            onTap: () {
                              Navigator.pop(context);
                              _extractScore();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.assignment),
                            title: Text(context.l10n.retrieveExams),
                            onTap: () {
                              Navigator.pop(context);
                              _extractExam();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.menu_open),
                label: Text(
                  context.l10n.importMenu,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
