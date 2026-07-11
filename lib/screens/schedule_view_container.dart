import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart';
import '../services/schedule_service.dart';
import '../utils/building_time_override.dart';
import '../utils/screen_breakpoints.dart';
import 'schedule_screen.dart';
import 'daily_schedule_screen.dart';
import '../widgets/draggable_floating_button.dart';
import 'package:mysues/l10n/legacy_text.dart';

/// 课表视图容器，管理周视图和日视图之间的切换
class ScheduleViewContainer extends StatefulWidget {
  const ScheduleViewContainer({super.key});

  /// 全局 key，用于外部触发视图切换
  static final GlobalKey<ScheduleViewContainerState> containerKey =
      GlobalKey<ScheduleViewContainerState>();

  @override
  State<ScheduleViewContainer> createState() => ScheduleViewContainerState();
}

class ScheduleViewContainerState extends State<ScheduleViewContainer> {
  bool _isDailyView = false;
  bool _isLoading = true;

  // FAB position (persisted)
  double _fabDx = -1;
  double _fabDy = -1;

  // Split-view state for large landscape screens
  final GlobalKey<ScheduleScreenState> _splitWeekKey =
      GlobalKey<ScheduleScreenState>();
  bool _isSplitDataLoading = false;
  bool _hasSplitDataLoaded = false;
  List<_SplitCourseEvent> _splitEvents = [];
  ScheduleTable? _splitTable;
  int _splitCurrentWeek = 1;
  int? _selectedCourseId;
  String? _selectedEventKey;
  final ScrollController _splitEventScrollController = ScrollController();
  final Map<String, GlobalKey> _splitEventKeys = {};
  Timer? _timeTicker;

  @override
  void initState() {
    super.initState();
    _startTimeTicker();
    _loadPreferences();
  }

  @override
  void dispose() {
    _timeTicker?.cancel();
    _splitEventScrollController.dispose();
    super.dispose();
  }

  void _startTimeTicker() {
    _timeTicker?.cancel();
    // Keep timeline sections (today/upcoming/past) fresh while page stays open.
    _timeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || !_hasSplitDataLoaded) return;
      setState(() {});
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isDailyView = prefs.getBool('is_daily_view') ?? false;
      _fabDx = prefs.getDouble('schedule_fab_dx') ?? -1;
      _fabDy = prefs.getDouble('schedule_fab_dy') ?? -1;
      _isLoading = false;
    });
    await _loadSplitData();
  }

  Future<void> _loadSplitData() async {
    if (_isSplitDataLoading) return;
    if (mounted) {
      setState(() {
        _isSplitDataLoading = true;
      });
    }

    await ScheduleDataService.initDefaultData();
    final results = await Future.wait([
      ScheduleDataService.loadScheduleTables(),
      ScheduleDataService.getCurrentTableId(),
    ]);

    final tables = results[0] as List<ScheduleTable>;
    final currentTableId = results[1] as int;
    if (tables.isEmpty) {
      if (!mounted) return;
      setState(() {
        _splitTable = null;
        _splitEvents = [];
        _isSplitDataLoading = false;
        _hasSplitDataLoaded = true;
      });
      return;
    }

    final table = tables.firstWhere(
      (t) => t.id == currentTableId,
      orElse: () => tables.first,
    );

    final dataResults = await Future.wait([
      ScheduleDataService.loadCourses(tableId: table.id),
      ScheduleDataService.loadTimeDetails(timeTableId: table.timeTableId),
    ]);

    final courses = dataResults[0] as List<Course>;
    final timeDetails = dataResults[1] as List<TimeDetail>;
    timeDetails.sort((a, b) => a.node.compareTo(b.node));

    final semesterStart = _semesterStartMonday(table.startDateObj);
    final visibleCourses = courses
        .where((c) => !c.isHidden || table.showHiddenCourses)
        .toList();
    final events = _buildSplitEvents(
      courses: visibleCourses,
      table: table,
      semesterStart: semesterStart,
      timeDetails: timeDetails,
    );
    final activeKeys = events.map((e) => e.uniqueKey).toSet();
    _splitEventKeys.removeWhere((key, _) => !activeKeys.contains(key));

    String? selectedEventKey = _selectedEventKey;
    int? selectedCourseId = _selectedCourseId;

    if (selectedEventKey != null &&
        !events.any((e) => e.uniqueKey == selectedEventKey)) {
      selectedEventKey = null;
    }
    if (selectedCourseId != null &&
        !events.any((e) => e.course.id == selectedCourseId)) {
      selectedCourseId = null;
    }

    if (selectedEventKey == null) {
      final defaultEvent = _pickDefaultEvent(events);
      if (defaultEvent != null) {
        selectedEventKey = defaultEvent.uniqueKey;
        selectedCourseId = defaultEvent.course.id;
      }
    }

    if (!mounted) return;
    setState(() {
      _splitTable = table;
      _splitEvents = events;
      _splitCurrentWeek = _calculateCurrentWeek(
        table.startDateObj,
      ).clamp(1, table.maxWeek);
      _selectedEventKey = selectedEventKey;
      _selectedCourseId = selectedCourseId;
      _isSplitDataLoading = false;
      _hasSplitDataLoaded = true;
    });
  }

  Future<void> _saveViewPreference(bool isDaily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_daily_view', isDaily);
  }

  Future<void> _saveFabPosition(double dx, double dy) async {
    _fabDx = dx;
    _fabDy = dy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('schedule_fab_dx', dx);
    await prefs.setDouble('schedule_fab_dy', dy);
  }

  void toggleView() {
    setState(() {
      _isDailyView = !_isDailyView;
    });
    _saveViewPreference(_isDailyView);
  }

  void setDailyView(bool daily) {
    if (_isDailyView != daily) {
      setState(() {
        _isDailyView = daily;
      });
      _saveViewPreference(daily);
    }
  }

  bool get isDailyView => _isDailyView;

  bool _useSplitLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenBreakpoints.isLargeDevice(context) && size.width > size.height;
  }

  // --- FAB logic ---

  bool get _shouldShowFab {
    if (_isDailyView) {
      return DailyScheduleScreen.currentState?.showFloatingButton ?? false;
    } else {
      return ScheduleScreen.currentState?.showFloatingButton ?? false;
    }
  }

  String get _fabLabel {
    if (_isDailyView) {
      final state = DailyScheduleScreen.currentState;
      if (state == null) return '';
      final d = state.selectedDate;
      return '${d.month}/${d.day}';
    } else {
      final state = ScheduleScreen.currentState;
      if (state == null) return '';
      return '${state.currentWeek}';
    }
  }

  bool get _isAtHome {
    if (_isDailyView) {
      return DailyScheduleScreen.currentState?.isViewingToday ?? true;
    } else {
      return ScheduleScreen.currentState?.isOnActualCurrentWeek ?? true;
    }
  }

  void _onFabTap() {
    if (_isDailyView) {
      final state = DailyScheduleScreen.currentState;
      if (state == null) return;
      if (state.isViewingToday) {
        _showDateJumpDialog(state);
      } else {
        state.jumpToToday();
      }
    } else {
      final state = ScheduleScreen.currentState;
      if (state == null) return;
      if (state.isOnActualCurrentWeek) {
        _showWeekJumpDialog(state);
      } else {
        state.jumpToActualCurrentWeek();
      }
    }
  }

  void _showWeekJumpDialog(ScheduleScreenState state) {
    final controller = TextEditingController();
    void tryJump(BuildContext ctx) {
      final text = controller.text.trim();
      final week = int.tryParse(text);
      if (week == null || text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: LText('请输入有效的周次数字')));
        return;
      }
      if (week < 1 || week > state.maxWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LText('周次超出范围，请输入 1-${state.maxWeek}')),
        );
        return;
      }
      Navigator.pop(ctx);
      state.jumpToWeek(week);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const LText('跳转到周次'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: legacyTranslate(context, '周次 (1-${state.maxWeek})'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => tryJump(ctx),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const LText('取消'),
            ),
            TextButton(onPressed: () => tryJump(ctx), child: const LText('跳转')),
          ],
        );
      },
    );
  }

  void _showDateJumpDialog(DailyScheduleScreenState state) {
    // Clamp initialDate to semester range
    final now = state.selectedDate;
    final first = state.semesterStart;
    final last = state.semesterEnd;
    final clamped = now.isBefore(first)
        ? first
        : (now.isAfter(last) ? last : now);

    showDatePicker(
      context: context,
      initialDate: clamped,
      firstDate: first,
      lastDate: last,
    ).then((date) {
      if (date != null) {
        state.jumpToDate(date);
      }
    });
  }

  void _handleSplitEventTap(_SplitCourseEvent event) {
    setState(() {
      _selectedCourseId = event.course.id;
      _selectedEventKey = event.uniqueKey;
      _splitCurrentWeek = event.week;
    });
    _scrollToEvent(event.uniqueKey);
    _splitWeekKey.currentState?.jumpToWeek(event.week);
  }

  void _handleSplitWeekChanged(int week) {
    if (!mounted || _splitCurrentWeek == week) return;
    setState(() {
      _splitCurrentWeek = week;
    });
  }

  void _handleSplitWeekCourseTap(Course course, int week) {
    final event =
        _findEvent(course.id, week) ?? _findFirstEventByCourse(course.id);
    setState(() {
      _selectedCourseId = course.id;
      _splitCurrentWeek = week;
      _selectedEventKey = event?.uniqueKey;
    });
    _scrollToEvent(event?.uniqueKey);
  }

  int get _splitActualCurrentWeek {
    final table = _splitTable;
    if (table == null) return 1;
    return _calculateCurrentWeek(table.startDateObj).clamp(1, table.maxWeek);
  }

  bool get _isOnSplitActualWeek => _splitCurrentWeek == _splitActualCurrentWeek;

  void _onSplitJumpTap() {
    final table = _splitTable;
    if (table == null) return;

    if (!_isOnSplitActualWeek) {
      final target = _splitActualCurrentWeek;
      setState(() {
        _splitCurrentWeek = target;
      });
      _splitWeekKey.currentState?.jumpToWeek(target);
      return;
    }

    _showSplitWeekJumpDialog(maxWeek: table.maxWeek);
  }

  void _showSplitWeekJumpDialog({required int maxWeek}) {
    final controller = TextEditingController();

    void tryJump(BuildContext dialogContext) {
      final text = controller.text.trim();
      final week = int.tryParse(text);
      if (week == null || text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: LText('请输入有效的周次数字')));
        return;
      }
      if (week < 1 || week > maxWeek) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: LText('周次超出范围，请输入 1-$maxWeek')));
        return;
      }

      Navigator.pop(dialogContext);
      setState(() {
        _splitCurrentWeek = week;
      });
      _splitWeekKey.currentState?.jumpToWeek(week);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const LText('跳转到周次'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: legacyTranslate(context, '周次 (1-$maxWeek)'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => tryJump(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const LText('取消'),
            ),
            TextButton(
              onPressed: () => tryJump(dialogContext),
              child: const LText('跳转'),
            ),
          ],
        );
      },
    );
  }

  _SplitCourseEvent? _findEvent(int courseId, int week) {
    for (final event in _splitEvents) {
      if (event.course.id == courseId && event.week == week) {
        return event;
      }
    }
    return null;
  }

  _SplitCourseEvent? _findFirstEventByCourse(int courseId) {
    for (final event in _splitEvents) {
      if (event.course.id == courseId) {
        return event;
      }
    }
    return null;
  }

  GlobalKey _eventItemKey(String uniqueKey) {
    return _splitEventKeys.putIfAbsent(uniqueKey, () => GlobalKey());
  }

  void _scrollToEvent(String? uniqueKey) {
    if (uniqueKey == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _splitEventKeys[uniqueKey];
      final targetContext = key?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.28,
      );
    });
  }

  List<_SplitCourseEvent> _buildSplitEvents({
    required List<Course> courses,
    required ScheduleTable table,
    required DateTime semesterStart,
    required List<TimeDetail> timeDetails,
  }) {
    final events = <_SplitCourseEvent>[];
    for (final course in courses) {
      for (int week = 1; week <= table.maxWeek; week++) {
        if (!course.inWeek(week)) continue;
        final date = semesterStart.add(
          Duration(days: (week - 1) * 7 + (course.day - 1)),
        );
        final startMinutes = _resolveCourseStartMinutes(course, timeDetails);
        final endMinutes = _resolveCourseEndMinutes(course, timeDetails);
        events.add(
          _SplitCourseEvent(
            course: course,
            week: week,
            date: DateUtils.dateOnly(date),
            startMinutes: startMinutes,
            endMinutes: endMinutes,
          ),
        );
      }
    }

    events.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byStart = a.startMinutes.compareTo(b.startMinutes);
      if (byStart != 0) return byStart;
      return a.course.courseName.compareTo(b.course.courseName);
    });
    return events;
  }

  _SplitCourseEvent? _pickDefaultEvent(List<_SplitCourseEvent> events) {
    if (events.isEmpty) return null;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    for (final event in events) {
      if (event.startDateTime.isAfter(now)) {
        return event;
      }
    }

    for (final event in events) {
      if (_isSameDay(event.date, today)) {
        return event;
      }
    }

    return events.first;
  }

  List<_SplitCourseEvent> get _todayEvents {
    final today = DateUtils.dateOnly(DateTime.now());
    return _splitEvents.where((e) => _isSameDay(e.date, today)).toList();
  }

  List<_SplitCourseEvent> get _upcomingEvents {
    final now = DateTime.now();
    return _splitEvents.where((e) => e.startDateTime.isAfter(now)).toList();
  }

  int _resolveCourseStartMinutes(Course course, List<TimeDetail> timeDetails) {
    if (course.startTime != null && course.startTime!.isNotEmpty) {
      final parsed = _parseTime(course.startTime!);
      if (parsed > 0) return parsed;
    }
    final override = BuildingTimeOverride.getOverrideStartTime(
      course.room,
      course.startNode,
    );
    if (override != null) return _parseTime(override);
    try {
      final detail = timeDetails.firstWhere((d) => d.node == course.startNode);
      return _parseTime(detail.startTime);
    } catch (_) {
      return 8 * 60;
    }
  }

  int _resolveCourseEndMinutes(Course course, List<TimeDetail> timeDetails) {
    if (course.endTime != null && course.endTime!.isNotEmpty) {
      final parsed = _parseTime(course.endTime!);
      if (parsed > 0) return parsed;
    }

    final endNode = course.startNode + course.step - 1;
    final override = BuildingTimeOverride.getOverrideEndTime(
      course.room,
      endNode,
    );
    if (override != null) return _parseTime(override);

    try {
      final detail = timeDetails.firstWhere((d) => d.node == endNode);
      return _parseTime(detail.endTime);
    } catch (_) {
      return _resolveCourseStartMinutes(course, timeDetails) + course.step * 45;
    }
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 0;
    return h * 60 + m;
  }

  int _calculateCurrentWeek(DateTime startDate) {
    final startMonday = _semesterStartMonday(startDate);
    final now = DateTime.now();
    final diff = now.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  DateTime _semesterStartMonday(DateTime startDate) {
    return DateUtils.dateOnly(
      startDate.subtract(Duration(days: startDate.weekday - 1)),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Widget _buildSplitLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelWidth = (size.width * 0.34).clamp(300.0, 420.0).toDouble();

    return Row(
      children: [
        SizedBox(width: panelWidth, child: _buildSplitEventPanel(context)),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
        Expanded(
          child: ScheduleScreen(
            key: _splitWeekKey,
            onWeekChanged: _handleSplitWeekChanged,
            onCourseTap: _handleSplitWeekCourseTap,
            onDataChanged: () {
              _loadSplitData();
            },
            highlightedCourseId: _selectedCourseId,
            showSwitchAction: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitEventPanel(BuildContext context) {
    final theme = Theme.of(context);
    final todayEvents = _todayEvents;
    final upcomingEvents = _upcomingEvents;

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LText(
                      _splitTable == null
                          ? '日程'
                          : '${_splitTable!.tableName} · 第$_splitCurrentWeek周',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: legacyTranslate(
                      context,
                      _isOnSplitActualWeek ? '跳转到指定周' : '回到当前周',
                    ),
                    onPressed: _onSplitJumpTap,
                    icon: Icon(
                      _isOnSplitActualWeek
                          ? Icons.calendar_today_rounded
                          : Icons.my_location_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isSplitDataLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSplitData,
                      child: ListView(
                        controller: _splitEventScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        children: [
                          _buildSectionTitle(context, '今天'),
                          if (todayEvents.isEmpty)
                            _buildEmptyHint(context, '今天暂无课程')
                          else
                            ...todayEvents.map(
                              (e) => _buildEventTile(context, e),
                            ),
                          const SizedBox(height: 14),
                          _buildSectionTitle(context, '即将发生'),
                          if (upcomingEvents.isEmpty)
                            _buildEmptyHint(context, '暂无即将发生课程')
                          else
                            ...upcomingEvents.map(
                              (e) => _buildEventTile(context, e),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
      child: Row(
        children: [
          LText(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LText(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, _SplitCourseEvent event) {
    final theme = Theme.of(context);
    final isSelected = _selectedEventKey == event.uniqueKey;
    final isPast = event.endDateTime.isBefore(DateTime.now());

    return Padding(
      key: _eventItemKey(event.uniqueKey),
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleSplitEventTap(event),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.22,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.55)
                  : theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: event.course.colorObj,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LText(
                      event.course.courseName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPast
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.65,
                              )
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  LText(
                    '第${event.week}周',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LText(
                localizedScheduleEventDate(
                  context,
                  event.date,
                  _formatMinutes(event.startMinutes),
                  _formatMinutes(event.endMinutes),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              if (event.course.room.isNotEmpty) ...[
                const SizedBox(height: 2),
                LText(
                  event.course.room,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final useSplit = _useSplitLayout(context);
    if (useSplit) {
      if (!_hasSplitDataLoaded && !_isSplitDataLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadSplitData();
          }
        });
      }
      return _buildSplitLayout(context);
    }

    final showFab = _shouldShowFab;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isDailyView
              ? DailyScheduleScreen(
                  key: const ValueKey('daily'),
                  onSwitchToWeek: () => setDailyView(false),
                )
              : ScheduleScreen(
                  key: const ValueKey('week'),
                  onSwitchToDaily: () => setDailyView(true),
                ),
        ),
        if (showFab)
          DraggableFloatingButton(
            label: _fabLabel,
            isAtHome: _isAtHome,
            initialDx: _fabDx,
            initialDy: _fabDy,
            onTap: _onFabTap,
            onPositionChanged: _saveFabPosition,
          ),
      ],
    );
  }
}

class _SplitCourseEvent {
  final Course course;
  final int week;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;

  const _SplitCourseEvent({
    required this.course,
    required this.week,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });

  String get uniqueKey =>
      '$week-${course.id}-${date.year}-${date.month}-${date.day}';

  DateTime get startDateTime => DateTime(
    date.year,
    date.month,
    date.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );

  DateTime get endDateTime => DateTime(
    date.year,
    date.month,
    date.day,
    endMinutes ~/ 60,
    endMinutes % 60,
  );
}
