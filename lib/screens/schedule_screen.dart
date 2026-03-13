import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart'; // Import Time models
import '../services/schedule_service.dart';
import '../services/theme_service.dart';
import 'add_course_screen.dart';
import 'schedule_settings_screen.dart';
import 'schedule_view_container.dart';
import 'import_classpdf_screen.dart'; // Import
import 'login_webview_screen.dart'; // Import
import '../utils/sync_disclaimer.dart';
import '../utils/building_time_override.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onSwitchToDaily;

  const ScheduleScreen({super.key, this.onSwitchToDaily});

  /// Static reference to current state (avoids GlobalKey conflicts with AnimatedSwitcher)
  static ScheduleScreenState? _currentState;
  static ScheduleScreenState? get currentState => _currentState;

  @override
  State<ScheduleScreen> createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _pageController;
  int _currentWeek = 1;
  int _actualCurrentWeek = 1;
  ScheduleTable? _currentTable;
  List<Course> _courses = [];
  List<TimeDetail> _timeDetails = []; // Store time details
  bool _isLoading = true;

  // UI Constants (loaded from ScheduleTable)
  double _timeColWidth = 50.0;
  double _headerHeight = 50.0;
  double _cellHeight = 60.0; // Default, will override

  // Public API for floating button
  int get currentWeek => _currentWeek;
  int get actualCurrentWeek => _actualCurrentWeek;
  int get maxWeek => _currentTable?.maxWeek ?? 30;
  bool get isOnActualCurrentWeek => _currentWeek == _actualCurrentWeek;
  bool get showFloatingButton => _currentTable?.showFloatingButton ?? true;

  void jumpToWeek(int week) {
    final page = (week - 1).clamp(0, maxWeek - 1);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void jumpToActualCurrentWeek() {
    jumpToWeek(_actualCurrentWeek);
  }

  @override
  void initState() {
    super.initState();
    ScheduleScreen._currentState = this;
    _pageController = PageController(initialPage: 0);
    _initData();
  }

  @override
  void dispose() {
    if (ScheduleScreen._currentState == this) {
      ScheduleScreen._currentState = null;
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    // Ensure default data exists
    await ScheduleDataService.initDefaultData();
    
    // 并行加载课表列表和当前课表ID
    final results = await Future.wait([
      ScheduleDataService.loadScheduleTables(),
      ScheduleDataService.getCurrentTableId(),
    ]);
    final tables = results[0] as List<ScheduleTable>;
    final currentTableId = results[1] as int;
    
    if (tables.isNotEmpty) {
      _currentTable = tables.firstWhere(
        (t) => t.id == currentTableId, 
        orElse: () => tables.first
      );
    }

    if (_currentTable != null) {
      // Calculate current week
      _currentWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
      _actualCurrentWeek = _currentWeek;
      // 并行加载课程和时间详情
      final dataResults = await Future.wait([
        ScheduleDataService.loadCourses(tableId: _currentTable!.id),
        ScheduleDataService.loadTimeDetails(timeTableId: _currentTable!.timeTableId),
      ]);
      _courses = dataResults[0] as List<Course>;
      _timeDetails = dataResults[1] as List<TimeDetail>;
      
      // Update UI settings
      _cellHeight = _currentTable!.itemHeight.toDouble();
      // Adjust page controller to current week (index 0 is week 1)
      int initialPage = (_currentWeek - 1).clamp(0, _currentTable!.maxWeek - 1);
      _pageController = PageController(initialPage: initialPage);
    }

    setState(() => _isLoading = false);
    // Notify container to show FAB after data is ready
    ScheduleViewContainer.containerKey.currentState?.setState(() {});
  }

  // _injectDemoCourses removed here
  
  String _getTimeRange(Course course) {
    if (course.startTime != null && course.endTime != null && course.startTime!.isNotEmpty) {
      return '${course.startTime} - ${course.endTime}';
    }
    if (_timeDetails.isEmpty) return '';
    try {
      final start = _timeDetails.firstWhere((t) => t.node == course.startNode);
      final endNode = course.startNode + course.step - 1;
      final end = _timeDetails.firstWhere((t) => t.node == endNode);

      // 特殊教学楼覆盖：根据教室判断是否使用特殊时间
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

  /// 将分钟数转换为网格内的像素位置。
  /// 以标准节次格子为锚点，在同一个节次内按时间比例插值定位。
  /// 课间休息不占用额外视觉空间，非标准时间的课程会在格子内偏移。
  double _timeMinutesToPosition(int minutes) {
    if (_timeDetails.isEmpty) return 0;

    final firstStart = _parseTime(_timeDetails.first.startTime);
    if (minutes <= firstStart) return 0;

    final lastEnd = _parseTime(_timeDetails.last.endTime);
    if (minutes >= lastEnd) return _currentTable!.nodes * _cellHeight;

    for (int i = 0; i < _timeDetails.length; i++) {
      final pStart = _parseTime(_timeDetails[i].startTime);
      final pEnd = _parseTime(_timeDetails[i].endTime);
      final slotTop = (_timeDetails[i].node - 1) * _cellHeight;
      final slotBottom = _timeDetails[i].node * _cellHeight;

      // 落在本节次时间范围内 → 在格子内按比例插值
      if (minutes >= pStart && minutes <= pEnd) {
        final fraction = (pEnd > pStart)
            ? (minutes - pStart) / (pEnd - pStart)
            : 0.0;
        return slotTop + fraction * (slotBottom - slotTop);
      }

      // 落在课间休息（本节次结束 ~ 下节次开始）
      if (i + 1 < _timeDetails.length) {
        final nextPStart = _parseTime(_timeDetails[i + 1].startTime);
        if (minutes > pEnd && minutes < nextPStart) {
          // 课间休息在网格中没有独立空间，线性插值到下一格子边界
          final nextSlotTop = (_timeDetails[i + 1].node - 1) * _cellHeight;
          final fraction = (nextPStart > pEnd)
              ? (minutes - pEnd) / (nextPStart - pEnd)
              : 0.0;
          return slotBottom + fraction * (nextSlotTop - slotBottom);
        }
      }
    }

    return 0;
  }

  double _calculateTop(Course course) {
    if (_timeDetails.isEmpty) {
      return (course.startNode - 1) * _cellHeight;
    }

    // 优先使用课程自带的开始时间
    if (course.startTime != null && course.startTime!.isNotEmpty) {
      final m = _parseTime(course.startTime!);
      if (m > 0) return _timeMinutesToPosition(m);
    }

    // 否则从时间表查找对应节次的标准开始时间（结果等同于旧逻辑的格子顶部）
    try {
      final detail = _timeDetails.firstWhere((t) => t.node == course.startNode);
      // 特殊教学楼覆盖
      final startTime = BuildingTimeOverride.getOverrideStartTime(course.room, course.startNode)
          ?? detail.startTime;
      return _timeMinutesToPosition(_parseTime(startTime));
    } catch (_) {
      return (course.startNode - 1) * _cellHeight;
    }
  }
  
  double _calculateHeight(Course course) {
    if (_timeDetails.isEmpty) {
      return course.step * _cellHeight;
    }

    int? startMinutes;
    int? endMinutes;

    // 优先使用课程自带的起止时间
    if (course.startTime != null && course.startTime!.isNotEmpty &&
        course.endTime != null && course.endTime!.isNotEmpty) {
      startMinutes = _parseTime(course.startTime!);
      endMinutes = _parseTime(course.endTime!);
    }

    // 若没有自定义时间，从时间表查找对应节次的标准起止时间
    if (startMinutes == null || endMinutes == null ||
        startMinutes == 0 || endMinutes == 0) {
      try {
        final startDetail = _timeDetails.firstWhere((t) => t.node == course.startNode);
        final endNode = course.startNode + course.step - 1;
        final endDetail = _timeDetails.firstWhere((t) => t.node == endNode);
        // 特殊教学楼覆盖
        final overrideStart = BuildingTimeOverride.getOverrideStartTime(course.room, course.startNode);
        final overrideEnd = BuildingTimeOverride.getOverrideEndTime(course.room, endNode);
        startMinutes = _parseTime(overrideStart ?? startDetail.startTime);
        endMinutes = _parseTime(overrideEnd ?? endDetail.endTime);
      } catch (_) {
        return course.step * _cellHeight;
      }
    }

    final h = _timeMinutesToPosition(endMinutes) - _timeMinutesToPosition(startMinutes);
    // 保证最小高度，避免极短课程不可见
    return h >= _cellHeight * 0.5 ? h : course.step * _cellHeight;
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
          decoration: isLiquidGlass ? null : BoxDecoration(
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
               // Handle bar
               Center(
                 child: Container(
                   width: 40, 
                   height: 5, 
                   decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.5)),
                 ),
               ),
               // Top buttons
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     TextButton(
                       onPressed: () {
                          // Allow deleting
                          _deleteCourse(context, course);
                       },
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
               // Title
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
                 child: Text(
                   course.courseName,
                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                 ),
               ),
               // Sub headers
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
               
               // Info Card
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
                               color: Colors.redAccent
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildDetailRow(
                               icon: Icons.access_time, 
                               content: '周${['一','二','三','四','五','六','日'][course.day-1]} ${course.nodeString} ${_getTimeRange(course)}',
                               color: Colors.redAccent
                             ),
                             if (course.teacher.isNotEmpty) ...[
                                const Divider(height: 1, indent: 56),
                                _buildDetailRow(
                                  icon: Icons.person_outline, 
                                  content: course.teacher,
                                  color: Colors.redAccent
                                ),
                             ],
                             if (course.room.isNotEmpty) ...[
                                const Divider(height: 1, indent: 56),
                                _buildDetailRow(
                                  icon: Icons.location_on_outlined, 
                                  content: course.room,
                                  color: Colors.redAccent
                                ),
                             ],
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 16),
                       // Actions Card
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
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制课程名称')));
                               }
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildActionRow(
                               icon: Icons.copy, 
                               text: '复制课程信息为文本',
                               color: Colors.redAccent,
                               onTap: () {
                                 final info = '${course.courseName}\n周${['一','二','三','四','五','六','日'][course.day-1]} ${course.nodeString} ${_getTimeRange(course)}\n${course.teacher} ${course.room}';
                                 Clipboard.setData(ClipboardData(text: info));
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制课程信息')));
                               }
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
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
                await ScheduleDataService.deleteCourse(course.id);
                _initData();
              }, 
              child: const Text('删除', style: TextStyle(color: Colors.red))
            ),
          ],
        )
      );
  }
  
  Future<void> _editCourse(BuildContext context, Course course) async {
     final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => AddCourseScreen(course: course)),
      );
      
      // If result is strict string 'deleted', it was deleted
      if (result == 'deleted') {
          _initData();
          return;
      }
      
      if (result != null && result is Course) {
          await ScheduleDataService.updateCourse(result);
          _initData();
      }
  }

  int _calculateCurrentWeek(DateTime startDate) {
    // 简单的周次计算逻辑
    // 确保startDate是周一
    final startMonday = startDate.subtract(Duration(days: startDate.weekday - 1));
    final now = DateTime.now();
    final diff = now.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
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
          decoration: isLiquidGlass ? null : BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.5)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Text("切换课表", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     IconButton(
                       icon: const Icon(Icons.add),
                       onPressed: () async {
                         Navigator.pop(context);
                         final existingNames = tables.map((t) => t.tableName).toList();
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
                     )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text("长按删除课表", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    final isCurrent = _currentTable?.id == table.id;
                    return ListTile(
                      title: Text(table.tableName),
                      subtitle: Text("开学: ${table.startDate}"),
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
                                  Navigator.pop(context); // Close dialog
                                  await ScheduleDataService.deleteScheduleTable(table.id);
                                  if (context.mounted) {
                                     Navigator.pop(context); // Close bottom sheet to avoid stale data
                                     _initData(); // Refresh, _initData handles fallback if current is deleted
                                  }
                                },
                                child: const Text('删除', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          )
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
      }
    );
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
        appBar: AppBar(title: const Text('我的课表')),
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
                child: const Text("新建课表")
              )
            ],
          )
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showScheduleManager(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_currentTable!.tableName, style: const TextStyle(fontSize: 14)),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
              Text(
                '第 $_currentWeek 周',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: ThemeService().liquidGlassEnabled ? Colors.transparent : null,
        elevation: ThemeService().liquidGlassEnabled ? 0 : null,
        actions: [
          Tooltip(
            message: '切换到日视图',
            child: IconButton(
              onPressed: widget.onSwitchToDaily,
              icon: const Icon(Icons.view_day_outlined, size: 22),
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
                          if (result == true) {
                            _initData();
                          }
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
                          if (result != null) {
                            _initData();
                          }
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
                          MaterialPageRoute(builder: (c) => ScheduleSettingsScreen(table: _currentTable!, existingNames: existingNames)),
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: _currentTable!.maxWeek,
        onPageChanged: (page) {
          setState(() {
            _currentWeek = page + 1;
          });
          // Notify container to refresh FAB label
          ScheduleViewContainer.containerKey.currentState?.setState(() {});
        },
        itemBuilder: (context, index) {
          final weekNum = index + 1;
          return _buildWeekSchedule(weekNum);
        },
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
                          Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
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
                                  MaterialPageRoute(builder: (c) => ScheduleSettingsScreen(table: _currentTable!, existingNames: existingNames)),
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

  Widget _buildWeekSchedule(int weekNum) {
    final weekStart = _currentTable!.startDateObj.add(Duration(days: (weekNum - 1) * 7));
    // Correct to Monday if necessary, though logic handled in model ideally
    final adjustedWeekStart = weekStart.subtract(Duration(days: weekStart.weekday - 1));

    // Calculate visible days
    List<int> visibleIndices = [0, 1, 2, 3, 4]; // Mon-Fri always visible
    if (_currentTable!.showSat) visibleIndices.add(5);
    if (_currentTable!.showSun) visibleIndices.add(6);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayColWidth = (constraints.maxWidth - _timeColWidth) / visibleIndices.length;
        
        return Column(
          children: [
            // Header (Date)
            SizedBox(
              height: _headerHeight,
              child: Row(
                children: [
                  SizedBox(width: _timeColWidth, child: Center(child: Text("${weekStart.month}\n月", textAlign: TextAlign.center,))),
                  ...visibleIndices.map((index) {
                    final date = adjustedWeekStart.add(Duration(days: index));
                    final isToday = DateTime.now().day == date.day && DateTime.now().month == date.month && DateTime.now().year == date.year;
                    return Container(
                      width: dayColWidth,
                      color: isToday ? Colors.blue.withValues(alpha: 0.1) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(['一','二','三','四','五','六','日'][index]),
                          Text("${date.day}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Column
                    SizedBox(
                      width: _timeColWidth,
                      child: Column(
                        children: List.generate(_currentTable!.nodes, (index) {
                          final node = index + 1;
                          final detail = _timeDetails.firstWhere((d) => d.node == node, orElse: () => TimeDetail(node: node, startTime: '', endTime: '', timeTableId: 0));
                          
                          return Container(
                            height: _cellHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${index + 1}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                                ),
                                if (detail.startTime.isNotEmpty) ...[
                                   Text(detail.startTime, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                   Text(detail.endTime, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                ]
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    // Courses
                    SizedBox(
                      width: constraints.maxWidth - _timeColWidth,
                      height: _currentTable!.nodes * _cellHeight,
                      child: Stack(
                        children: [
                          // Background Grid Lines
                          ...List.generate(_currentTable!.nodes, (i) {
                             return Positioned(
                               top: (i + 1) * _cellHeight,
                               left: 0, 
                               right: 0,
                               child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                             );
                          }),
                          
                          // Generic Course Builder
                          ...() {
                             final List<Widget> widgets = [];
                             final activeCourses = _courses.where((c) => c.inWeek(weekNum)).toList();
                             
                             // Set to track occupied slots to prevent overlapping
                             // Format: "day-node" e.g. "1-3" (Monday, Node 3)
                             final Set<String> occupiedSlots = {};
                             
                             // 1. Add Active Courses (High Priority)
                             for (var course in activeCourses) {
                               widgets.add(_buildSingleCourseItem(context, course, visibleIndices, dayColWidth, false));
                               // Mark slots as occupied
                               for(int i = 0; i < course.step; i++) {
                                 occupiedSlots.add("${course.day}-${course.startNode + i}");
                               }
                             }
                             
                             // 2. Add Other Week Courses
                             // Logic: Look ahead from next week. The first course found for an empty slot is displayed.
                             if (_currentTable!.showOtherWeekCourse) {
                                // Iterate weeks from next week to end of semester
                                for (int w = weekNum + 1; w <= _currentTable!.maxWeek; w++) {
                                   final futureCourses = _courses.where((c) => c.inWeek(w)).toList();
                                   
                                   for (var course in futureCourses) {
                                       // Check if this course's slots are already filled
                                       bool isBlocked = false;
                                       for(int i = 0; i < course.step; i++) {
                                          if (occupiedSlots.contains("${course.day}-${course.startNode + i}")) {
                                            isBlocked = true;
                                            break;
                                          }
                                       }
                                       
                                       if (!isBlocked) {
                                          widgets.add(_buildSingleCourseItem(context, course, visibleIndices, dayColWidth, true));
                                          // Mark slots as occupied so further weeks don't override this one
                                          // (We show the SOONEST future course)
                                          for(int i = 0; i < course.step; i++) {
                                             occupiedSlots.add("${course.day}-${course.startNode + i}");
                                          }
                                       }
                                   }
                                }
                             }
                             
                             return widgets;
                          }(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleCourseItem(BuildContext context, Course course, List<int> visibleIndices, double dayColWidth, bool isNonCurrentWeek) {
      // Correct day index (1-7) -> (0-6)
      final dayIndex = course.day - 1;
      
      // Calculate display column index
      final displayIndex = visibleIndices.indexOf(dayIndex);
      
      // If day is not visible, skip rendering
      if (displayIndex == -1) return const SizedBox();
      
      final top = _calculateTop(course);
      final height = _calculateHeight(course);

      // Get start time string — 优先使用课程自带的 startTime
      String? startTimeStr;
      if (course.startTime != null && course.startTime!.isNotEmpty) {
        startTimeStr = course.startTime;
      } else {
        // 优先使用教学楼覆盖时间
        final override = BuildingTimeOverride.getOverrideStartTime(course.room, course.startNode);
        if (override != null) {
          startTimeStr = override;
        } else if (_timeDetails.isNotEmpty) {
          try {
            final detail = _timeDetails.firstWhere((d) => d.node == course.startNode);
            startTimeStr = detail.startTime;
          } catch (_) {}
        }
      }

      // Adjust styles for non-current week
      final bgColor = isNonCurrentWeek 
          ? course.colorObj.withValues(alpha: 0.3) // Example: lighter/dimmer
          : course.colorObj;
      final textColor = isNonCurrentWeek
          ? Color(_currentTable!.courseTextColor).withValues(alpha: 0.6)
          : Color(_currentTable!.courseTextColor);

      return Positioned(
        left: displayIndex * dayColWidth,
        top: top,
        width: dayColWidth - 1, // spacing
        height: height - 1, // spacing
        child: GestureDetector(
          onTap: () => _showCourseDetail(context, course),
          child: Container(
            margin: const EdgeInsets.all(1),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: isNonCurrentWeek ? Border.all(color: Colors.grey.withValues(alpha:0.3)) : null,
            ),
            child: Column(
              children: [
                if (_currentTable!.showTime && startTimeStr != null && startTimeStr.isNotEmpty)
                  Text(
                    startTimeStr,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isNonCurrentWeek)
                        Text(
                          "[非本周]",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      Text(
                        course.courseName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (course.room.isNotEmpty)
                        Text(
                          course.room,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
} // End of _ScheduleScreenState class? No, we are replacing inside the class method.
// Wait, I am pasting _buildSingleCourseItem OUTSIDE the method but inside the class.
// But the replace_string function needs context.
// Let's be careful about brackets.

