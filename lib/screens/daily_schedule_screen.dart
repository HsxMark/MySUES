import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart';
import '../services/schedule_service.dart';
import '../services/theme_service.dart';
import 'add_course_screen.dart';
import 'schedule_settings_screen.dart';
import 'schedule_view_container.dart';
import 'import_classpdf_screen.dart';
import 'login_webview_screen.dart';
import '../utils/sync_disclaimer.dart';
import '../utils/building_time_override.dart';

class DailyScheduleScreen extends StatefulWidget {
  final VoidCallback? onSwitchToWeek;

  const DailyScheduleScreen({super.key, this.onSwitchToWeek});

  /// Static reference to current state (avoids GlobalKey conflicts with AnimatedSwitcher)
  static DailyScheduleScreenState? _currentState;
  static DailyScheduleScreenState? get currentState => _currentState;

  @override
  State<DailyScheduleScreen> createState() => DailyScheduleScreenState();
}

class DailyScheduleScreenState extends State<DailyScheduleScreen> {
  ScheduleTable? _currentTable;
  List<Course> _courses = [];
  List<TimeDetail> _timeDetails = [];
  bool _isLoading = true;
  int _currentWeek = 1;
  DateTime _selectedDate = DateTime.now();
  late PageController _pageController;
  late PageController _weekPageController;
  bool _isSyncingPages = false;
  int _totalDays = 1;
  int _totalWeeks = 1;
  DateTime _semesterStart = DateTime.now();

  static const List<String> _weekDayNames = ['一', '二', '三', '四', '五', '六', '日'];

  // Public API for floating button
  DateTime get selectedDate => _selectedDate;
  DateTime get semesterStart => _semesterStart;
  DateTime get semesterEnd => _semesterStart.add(Duration(days: _totalDays - 1));
  bool get showFloatingButton => _currentTable?.showFloatingButton ?? true;

  bool get isViewingToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void jumpToDate(DateTime date) {
    final dayIndex = date.difference(_semesterStart).inDays.clamp(0, _totalDays - 1);
    _pageController.animateToPage(
      dayIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void jumpToToday() {
    jumpToDate(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    DailyScheduleScreen._currentState = this;
    _pageController = PageController();
    _weekPageController = PageController();
    _initData();
  }

  @override
  void dispose() {
    if (DailyScheduleScreen._currentState == this) {
      DailyScheduleScreen._currentState = null;
    }
    _pageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    await ScheduleDataService.initDefaultData();

    final results = await Future.wait([
      ScheduleDataService.loadScheduleTables(),
      ScheduleDataService.getCurrentTableId(),
    ]);
    final tables = results[0] as List<ScheduleTable>;
    final currentTableId = results[1] as int;

    if (tables.isNotEmpty) {
      _currentTable = tables.firstWhere(
        (t) => t.id == currentTableId,
        orElse: () => tables.first,
      );
    }

    if (_currentTable != null) {
      _currentWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
      final dataResults = await Future.wait([
        ScheduleDataService.loadCourses(tableId: _currentTable!.id),
        ScheduleDataService.loadTimeDetails(timeTableId: _currentTable!.timeTableId),
      ]);
      _courses = dataResults[0] as List<Course>;
      _timeDetails = dataResults[1] as List<TimeDetail>;

      // 计算学期起始周一和总天数
      _semesterStart = _currentTable!.startDateObj.subtract(
        Duration(days: _currentTable!.startDateObj.weekday - 1),
      );
      _totalWeeks = _currentTable!.maxWeek;
      _totalDays = _totalWeeks * 7;

      // 设置PageController到今天对应的页
      final todayIndex = _selectedDate.difference(_semesterStart).inDays.clamp(0, _totalDays - 1);
      final todayWeekIndex = (todayIndex / 7).floor().clamp(0, _totalWeeks - 1);
      _pageController = PageController(initialPage: todayIndex);
      _weekPageController = PageController(initialPage: todayWeekIndex);
    }

    setState(() => _isLoading = false);
    // Notify container to show FAB after data is ready
    ScheduleViewContainer.containerKey.currentState?.setState(() {});
  }

  int _calculateCurrentWeek(DateTime startDate) {
    final startMonday = startDate.subtract(Duration(days: startDate.weekday - 1));
    final now = DateTime.now();
    final diff = now.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  int _weekForDate(DateTime date) {
    if (_currentTable == null) return 1;
    final startMonday = _currentTable!.startDateObj.subtract(
      Duration(days: _currentTable!.startDateObj.weekday - 1),
    );
    final diff = date.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  String _getTimeRange(Course course) {
    if (course.startTime != null && course.endTime != null && course.startTime!.isNotEmpty) {
      return '${course.startTime} - ${course.endTime}';
    }
    if (_timeDetails.isEmpty) return '';
    try {
      final start = _timeDetails.firstWhere((t) => t.node == course.startNode);
      final endNode = course.startNode + course.step - 1;
      final end = _timeDetails.firstWhere((t) => t.node == endNode);

      final startTime = BuildingTimeOverride.getOverrideStartTime(course.room, course.startNode)
          ?? start.startTime;
      final endTime = BuildingTimeOverride.getOverrideEndTime(course.room, endNode)
          ?? end.endTime;
      return '$startTime - $endTime';
    } catch (e) {
      return '';
    }
  }

  int _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  /// 获取课程的开始时间（分钟数），用于排序
  int _courseStartMinutes(Course course) {
    if (course.startTime != null && course.startTime!.isNotEmpty) {
      final m = _parseTime(course.startTime!);
      if (m > 0) return m;
    }
    final override = BuildingTimeOverride.getOverrideStartTime(course.room, course.startNode);
    if (override != null) return _parseTime(override);
    try {
      final detail = _timeDetails.firstWhere((t) => t.node == course.startNode);
      return _parseTime(detail.startTime);
    } catch (_) {
      return course.startNode * 60;
    }
  }

  /// 获取当天需要显示的课程
  List<Course> _getCoursesForDate(DateTime date) {
    final week = _weekForDate(date);
    final dayOfWeek = date.weekday; // 1=Mon ... 7=Sun
    final filtered = _courses.where((c) => c.day == dayOfWeek && c.inWeek(week)).toList();
    filtered.sort((a, b) => _courseStartMinutes(a).compareTo(_courseStartMinutes(b)));
    return filtered;
  }

  /// 获取时间轴的小时列表
  List<int> _getTimelineHours() {
    if (_timeDetails.isEmpty) return List.generate(13, (i) => i + 8); // 8:00 - 20:00
    final firstHour = _parseTime(_timeDetails.first.startTime) ~/ 60;
    final lastHour = (_parseTime(_timeDetails.last.endTime) / 60).ceil();
    return List.generate(lastHour - firstHour + 1, (i) => i + firstHour);
  }

  /// 将分钟数转换为时间轴上的像素位置
  double _minutesToPosition(int minutes, double hourHeight, int firstHour) {
    return (minutes - firstHour * 60) / 60.0 * hourHeight;
  }

  String _semesterLabel() {
    if (_currentTable == null) return '';
    return _currentTable!.tableName;
  }

  void _showCourseDetail(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isLiquidGlass = ThemeService().liquidGlassEnabled;
        final theme = Theme.of(context);

        Widget sheet = Container(
          decoration: isLiquidGlass
              ? null
              : BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
          padding: const EdgeInsets.only(top: 8),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _deleteCourse(context, course),
                      child: const Text('删除', style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _editCourse(context, course);
                      },
                      child: const Text('编辑', style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
                child: Text(
                  course.courseName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("详情", style: TextStyle(color: Colors.grey)),
                    Text("以下内容可长按复制", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              content: '第 ${course.startWeek} - ${course.endWeek} 周',
                              color: Colors.redAccent,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildDetailRow(
                              icon: Icons.access_time,
                              content: '周${_weekDayNames[course.day - 1]} ${course.nodeString} ${_getTimeRange(course)}',
                              color: Colors.redAccent,
                            ),
                            if (course.teacher.isNotEmpty) ...[
                              const Divider(height: 1, indent: 56),
                              _buildDetailRow(
                                icon: Icons.person_outline,
                                content: course.teacher,
                                color: Colors.redAccent,
                              ),
                            ],
                            if (course.room.isNotEmpty) ...[
                              const Divider(height: 1, indent: 56),
                              _buildDetailRow(
                                icon: Icons.location_on_outlined,
                                content: course.room,
                                color: Colors.redAccent,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildActionRow(
                              icon: Icons.copy,
                              text: '复制课程名称',
                              color: Colors.redAccent,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: course.courseName));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已复制课程名称')),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildActionRow(
                              icon: Icons.copy,
                              text: '复制课程信息为文本',
                              color: Colors.redAccent,
                              onTap: () {
                                final info =
                                    '${course.courseName}\n周${_weekDayNames[course.day - 1]} ${course.nodeString} ${_getTimeRange(course)}\n${course.teacher} ${course.room}';
                                Clipboard.setData(ClipboardData(text: info));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已复制课程信息')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (isLiquidGlass) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          final isDark = brightness == Brightness.dark;
          sheet = LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings.figma(
              depth: 50,
              refraction: 100,
              dispersion: 4,
              frost: 2,
              lightAngle: math.pi / 4,
              glassColor: theme.colorScheme.surface.withValues(alpha: 0.8),
              lightIntensity: isDark ? 70 : 50,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            child: Material(
              color: Colors.transparent,
              child: sheet,
            ),
          );
        }

        return sheet;
      },
    );
  }

  Widget _buildDetailRow({required IconData icon, required String content, required Color color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(content, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
      },
    );
  }

  Widget _buildActionRow({required IconData icon, required String text, required Color color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: const TextStyle(fontSize: 16, color: Colors.redAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  void _deleteCourse(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确认要删除 "${course.courseName}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await ScheduleDataService.deleteCourse(course.id);
              _initData();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editCourse(BuildContext context, Course course) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => AddCourseScreen(course: course)),
    );
    if (result == 'deleted') {
      _initData();
      return;
    }
    if (result != null && result is Course) {
      await ScheduleDataService.updateCourse(result);
      _initData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentTable == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('每日课表')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('没有课表数据，请先创建课表'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final allTables = await ScheduleDataService.loadScheduleTables();
                  final existingNames = allTables.map((t) => t.tableName).toList();
                  if (!context.mounted) return;
                  final newTable = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => ScheduleSettingsScreen(existingNames: existingNames)),
                  );
                  if (newTable != null && newTable is ScheduleTable) {
                    await ScheduleDataService.addScheduleTable(newTable);
                    await ScheduleDataService.setCurrentTableId(newTable.id);
                    _initData();
                  }
                },
                child: const Text("新建课表"),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isLiquidGlass = ThemeService().liquidGlassEnabled;
    final weekNum = _weekForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_selectedDate.month}月',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: isLiquidGlass ? Colors.transparent : null,
        elevation: isLiquidGlass ? 0 : null,
        actions: [
          Tooltip(
            message: '切换到周视图',
            child: IconButton(
              onPressed: widget.onSwitchToWeek,
              icon: const Icon(Icons.view_week_outlined, size: 22),
            ),
          ),
          ListenableBuilder(
            listenable: ThemeService(),
            builder: (context, _) {
              if (ThemeService().liquidGlassEnabled) {
                return IconButton(
                  onPressed: () => _showLiquidGlassMenu(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: '菜单',
                );
              }
              return MenuAnchor(
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                    tooltip: '菜单',
                  );
                },
                menuChildren: [
                  SubmenuButton(
                    leadingIcon: const Icon(Icons.download),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.sync_alt),
                        onPressed: () async {
                          if (!await showSyncDisclaimer(context)) return;
                          if (!mounted) return;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => const LoginWebviewScreen()),
                          );
                          if (result == true) _initData();
                        },
                        child: const Text('从教务导入'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => const ImportClassPdfScreen()),
                          );
                          if (result != null) _initData();
                        },
                        child: const Text('从PDF导入'),
                      ),
                    ],
                    child: const Text('导入课表'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add),
                    onPressed: () async {
                      if (_currentTable != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => AddCourseScreen(course: null)),
                        );
                        if (result != null && result is Course) {
                          result.tableId = _currentTable!.id;
                          await ScheduleDataService.addCourse(result);
                          _initData();
                        }
                      }
                    },
                    child: const Text('添加课程'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.settings),
                    onPressed: () async {
                      if (_currentTable != null) {
                        final allTables = await ScheduleDataService.loadScheduleTables();
                        final existingNames = allTables
                            .where((t) => t.id != _currentTable!.id)
                            .map((t) => t.tableName)
                            .toList();
                        if (!context.mounted) return;
                        final newTable = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ScheduleSettingsScreen(table: _currentTable!, existingNames: existingNames),
                          ),
                        );
                        if (newTable != null && newTable is ScheduleTable) {
                          await ScheduleDataService.updateScheduleTable(newTable);
                          _initData();
                        }
                      }
                    },
                    child: const Text('课表设置'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week day selector (swipeable)
          _buildWeekDaySelector(theme),
          // Semester & week info bar
          _buildInfoBar(weekNum, theme),
          // Course list / timeline (swipeable by day)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalDays,
              onPageChanged: (index) {
                final newDate = _semesterStart.add(Duration(days: index));
                setState(() {
                  _selectedDate = newDate;
                });
                // Notify container to refresh FAB label
                ScheduleViewContainer.containerKey.currentState?.setState(() {});
                // 同步周选择器
                final targetWeek = (index / 7).floor().clamp(0, _totalWeeks - 1);
                if (!_isSyncingPages && _weekPageController.hasClients) {
                  final currentWeekPage = _weekPageController.page?.round() ?? 0;
                  if (currentWeekPage != targetWeek) {
                    _isSyncingPages = true;
                    _weekPageController.animateToPage(
                      targetWeek,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ).then((_) => _isSyncingPages = false);
                  }
                }
              },
              itemBuilder: (context, index) {
                final date = _semesterStart.add(Duration(days: index));
                final courses = _getCoursesForDate(date);
                if (courses.isEmpty) {
                  return _buildDailyTimeline(courses, theme, date);
                }
                return _buildDailyTimeline(courses, theme, date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector(ThemeData theme) {
    final now = DateTime.now();
    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _weekPageController,
        itemCount: _totalWeeks,
        onPageChanged: (weekIndex) {
          if (_isSyncingPages) return;
          // 保持同一星期几，切换到新的周
          final weekday = _selectedDate.weekday; // 1=Mon...7=Sun
          final newDate = _semesterStart.add(Duration(days: weekIndex * 7 + weekday - 1));
          final dayIndex = newDate.difference(_semesterStart).inDays.clamp(0, _totalDays - 1);
          setState(() {
            _selectedDate = newDate;
          });
          // 同步日视图
          if (_pageController.hasClients) {
            _isSyncingPages = true;
            _pageController.animateToPage(
              dayIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            ).then((_) => _isSyncingPages = false);
          }
        },
        itemBuilder: (context, weekIndex) {
          final monday = _semesterStart.add(Duration(days: weekIndex * 7));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: List.generate(7, (index) {
                final date = monday.add(Duration(days: index));
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final pageIndex = date.difference(_semesterStart).inDays.clamp(0, _totalDays - 1);
                      _pageController.animateToPage(
                        pageIndex,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDayNames[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: isToday
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? (isToday
                                      ? theme.colorScheme.surface
                                      : theme.colorScheme.onPrimary)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBar(int weekNum, ThemeData theme) {
    final dayName = _weekDayNames[_selectedDate.weekday - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showScheduleManager(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_semesterLabel()} · 第 $weekNum 周 周$dayName',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleManager(BuildContext context) async {
    final tables = await ScheduleDataService.loadScheduleTables();
    if (!context.mounted) return;

    final isLiquidGlass = ThemeService().liquidGlassEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLiquidGlass ? Colors.transparent : null,
      builder: (context) {
        final theme = Theme.of(context);

        Widget sheet = Container(
          decoration: isLiquidGlass
              ? null
              : BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('切换课表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        Navigator.pop(context);
                        final existingNames = tables.map((t) => t.tableName).toList();
                        if (!this.context.mounted) return;
                        final newTable = await Navigator.push(
                          this.context,
                          MaterialPageRoute(builder: (c) => ScheduleSettingsScreen(existingNames: existingNames)),
                        );
                        if (newTable != null && newTable is ScheduleTable) {
                          await ScheduleDataService.addScheduleTable(newTable);
                          await ScheduleDataService.setCurrentTableId(newTable.id);
                          _initData();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text('长按删除课表', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    final isCurrent = _currentTable?.id == table.id;
                    return ListTile(
                      title: Text(table.tableName),
                      subtitle: Text('开学: ${table.startDate}'),
                      trailing: isCurrent ? const Icon(Icons.check, color: Colors.blue) : null,
                      selected: isCurrent,
                      onTap: () async {
                        await ScheduleDataService.setCurrentTableId(table.id);
                        if (context.mounted) Navigator.pop(context);
                        _initData();
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除课表'),
                            content: Text('确认要删除课表 "${table.tableName}" 吗？\n删除后该课表下的所有课程也会被清空。'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await ScheduleDataService.deleteScheduleTable(table.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _initData();
                                  }
                                },
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );

        if (isLiquidGlass) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          final isDark = brightness == Brightness.dark;
          sheet = LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings.figma(
              depth: 50,
              refraction: 100,
              dispersion: 4,
              frost: 2,
              lightAngle: math.pi / 4,
              glassColor: theme.colorScheme.surface.withValues(alpha: 0.8),
              lightIntensity: isDark ? 70 : 50,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            child: Material(
              color: Colors.transparent,
              child: sheet,
            ),
          );
        }

        return sheet;
      },
    );
  }

  Widget _buildDailyTimeline(List<Course> courses, ThemeData theme, DateTime date) {
    final hours = _getTimelineHours();
    if (hours.isEmpty) return const SizedBox();
    final firstHour = hours.first;
    const double hourHeight = 60.0;
    const double leftMargin = 56.0;
    final totalHeight = hours.length * hourHeight;

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Hour labels and grid lines
            ...hours.map((hour) {
              final y = (hour - firstHour) * hourHeight;
              return Positioned(
                top: y,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: leftMargin,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        margin: const EdgeInsets.only(top: 7),
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Course cards
            ...courses.map((course) {
              final timeRange = _getTimeRange(course);
              int startMin = _courseStartMinutes(course);
              int endMin;
              if (course.endTime != null && course.endTime!.isNotEmpty) {
                endMin = _parseTime(course.endTime!);
              } else {
                final endNode = course.startNode + course.step - 1;
                final overrideEnd = BuildingTimeOverride.getOverrideEndTime(course.room, endNode);
                if (overrideEnd != null) {
                  endMin = _parseTime(overrideEnd);
                } else {
                  try {
                    final endDetail = _timeDetails.firstWhere((t) => t.node == endNode);
                    endMin = _parseTime(endDetail.endTime);
                  } catch (_) {
                    endMin = startMin + course.step * 45;
                  }
                }
              }

              final top = _minutesToPosition(startMin, hourHeight, firstHour);
              final height = math.max((endMin - startMin) / 60.0 * hourHeight, 48.0);

              return Positioned(
                top: top,
                left: leftMargin + 4,
                right: 12,
                height: height,
                child: GestureDetector(
                  onTap: () => _showCourseDetail(context, course),
                  child: Container(
                    decoration: BoxDecoration(
                      color: course.colorObj,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          course.courseName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(_currentTable!.courseTextColor),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeRange.isNotEmpty || course.room.isNotEmpty)
                          const SizedBox(height: 4),
                        if (timeRange.isNotEmpty || course.room.isNotEmpty)
                          Text(
                            [timeRange, if (course.room.isNotEmpty) course.room].where((s) => s.isNotEmpty).join(' · '),
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(_currentTable!.courseTextColor).withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Current time indicator
            if (isToday)
              Positioned(
                top: _minutesToPosition(nowMinutes, hourHeight, firstHour) - 1,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 2, color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLiquidGlassMenu(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final baseColor = theme.colorScheme.surface;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss menu',
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight, right: 8),
              child: LiquidGlass.withOwnLayer(
                settings: LiquidGlassSettings(
                  refractiveIndex: 1.21,
                  thickness: 30,
                  blur: 8,
                  saturation: 1.5,
                  lightIntensity: isDark ? .7 : 1,
                  ambientStrength: isDark ? .2 : .5,
                  lightAngle: math.pi / 4,
                  glassColor: baseColor.withValues(alpha: 0.6),
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                child: Material(
                  color: Colors.transparent,
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                            child: Text(
                              '导入课表',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.sync_alt,
                            label: '从教务导入',
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              if (!await showSyncDisclaimer(context)) return;
                              if (!mounted) return;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const LoginWebviewScreen()),
                              );
                              if (result == true) _initData();
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.picture_as_pdf,
                            iconColor: Colors.redAccent,
                            label: '从PDF导入',
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => const ImportClassPdfScreen()),
                              );
                              if (result != null) _initData();
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.add,
                            label: '添加课程',
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              if (_currentTable != null) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (c) => AddCourseScreen(course: null)),
                                );
                                if (result != null && result is Course) {
                                  result.tableId = _currentTable!.id;
                                  await ScheduleDataService.addCourse(result);
                                  _initData();
                                }
                              }
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.settings,
                            label: '课表设置',
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              if (_currentTable != null) {
                                final allTables = await ScheduleDataService.loadScheduleTables();
                                final existingNames = allTables
                                    .where((t) => t.id != _currentTable!.id)
                                    .map((t) => t.tableName)
                                    .toList();
                                if (!context.mounted) return;
                                final newTable = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => ScheduleSettingsScreen(table: _currentTable!, existingNames: existingNames),
                                  ),
                                );
                                if (newTable != null && newTable is ScheduleTable) {
                                  await ScheduleDataService.updateScheduleTable(newTable);
                                  _initData();
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildLiquidGlassMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
