import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart'; // Import Time models
import '../services/schedule_service.dart';
import 'add_course_screen.dart';
import 'schedule_settings_screen.dart';
import 'import_classpdf_screen.dart'; // Import
import 'login_webview_screen.dart'; // Import

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _pageController;
  int _currentWeek = 1;
  ScheduleTable? _currentTable;
  List<Course> _courses = [];
  List<TimeDetail> _timeDetails = []; // Store time details
  bool _isLoading = true;

  // UI Constants (loaded from ScheduleTable)
  double _timeColWidth = 50.0;
  double _headerHeight = 50.0;
  double _cellHeight = 60.0; // Default, will override

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    // Ensure default data exists
    await ScheduleDataService.initDefaultData();
    
    final tables = await ScheduleDataService.loadScheduleTables();
    final currentTableId = await ScheduleDataService.getCurrentTableId();
    
    if (tables.isNotEmpty) {
      _currentTable = tables.firstWhere(
        (t) => t.id == currentTableId, 
        orElse: () => tables.first
      );
    }

    if (_currentTable != null) {
      // Calculate current week
      _currentWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
      // Load courses
      _courses = await ScheduleDataService.loadCourses(tableId: _currentTable!.id);
      // Load time details
      _timeDetails = await ScheduleDataService.loadTimeDetails(timeTableId: _currentTable!.timeTableId);
      
      // Update UI settings
      _cellHeight = _currentTable!.itemHeight.toDouble();
      // Adjust page controller to current week (index 0 is week 1)
      int initialPage = (_currentWeek - 1).clamp(0, _currentTable!.maxWeek - 1);
      _pageController = PageController(initialPage: initialPage);
    }

    setState(() => _isLoading = false);
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
      return '${start.startTime} - ${end.endTime}';
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

  double _calculateTop(Course course) {
    // 强制使用节次计算，避免因课件时间包含课间休息导致色块错位
    return (course.startNode - 1) * _cellHeight;
  }
  
  double _calculateHeight(Course course) {
     // 强制使用节次计算，避免因课件时间包含课间休息导致色块超出网格
     return course.step * _cellHeight;
  }

  void _showCourseDetail(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Adaptive background
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.only(top: 8),
          height: MediaQuery.of(context).size.height * 0.75, // Take up typical sheet height
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
    
    showModalBottomSheet(
      context: context, 
      builder: (context) {
        return Column(
          children: [
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
                       final newTable = await Navigator.push(
                         context,
                         MaterialPageRoute(builder: (c) => const ScheduleSettingsScreen()),
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
        );
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
                    final newTable = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const ScheduleSettingsScreen()),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentTable!.tableName),
              const Icon(Icons.arrow_drop_down)
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          MenuAnchor(
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
                      result.tableId = _currentTable!.id; // Ensure table ID is set
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
                    final newTable = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => ScheduleSettingsScreen(table: _currentTable!)),
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
        },
        itemBuilder: (context, index) {
          final weekNum = index + 1;
          return _buildWeekSchedule(weekNum);
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '回到本周',
        onPressed: () {
           if (_currentTable != null) {
              int todayWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
              // clamp to valid range
              final targetPage = (todayWeek - 1).clamp(0, _currentTable!.maxWeek - 1);
              _pageController.jumpToPage(targetPage);
           }
        },
        child: const Icon(Icons.today),
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
            // Week number header
            Container(
              height: 30, // Small height for week number
              alignment: Alignment.center,
              color: Colors.grey.withValues(alpha: 0.05),
              child: Text(
                 "第 $weekNum 周",
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
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

      // Get start time string
      String? startTimeStr;
      if (_timeDetails.isNotEmpty) {
        try {
          final detail = _timeDetails.firstWhere((d) => d.node == course.startNode);
          startTimeStr = detail.startTime;
        } catch (_) {}
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

