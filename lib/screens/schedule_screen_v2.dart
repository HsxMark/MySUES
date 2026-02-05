import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart'; // Import Time models
import '../services/schedule_service.dart';
import 'add_course_screen_v2.dart';
import 'schedule_settings_screen.dart';

class ScheduleScreenV2 extends StatefulWidget {
  const ScheduleScreenV2({super.key});

  @override
  State<ScheduleScreenV2> createState() => _ScheduleScreenV2State();
}

class _ScheduleScreenV2State extends State<ScheduleScreenV2> {
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
  
  void _showCourseDetail(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(course.courseName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course.room.isNotEmpty) 
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(course.room),
                  contentPadding: EdgeInsets.zero,
                ),
              if (course.teacher.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(course.teacher),
                  contentPadding: EdgeInsets.zero,
                ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('周${['一','二','三','四','五','六','日'][course.day-1]} ${course.nodeString}'),
                subtitle: Text('${course.startWeek}-${course.endWeek}周'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => AddCourseScreenV2(course: course)),
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
              },
              child: const Text('编辑'),
            ),
          ],
        );
      },
    );
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加课程',
            onPressed: () async {
              if (_currentTable != null) {
                final newCourse = Course(
                  courseName: '', 
                  day: 1, 
                  startNode: 1, 
                  startWeek: 1, 
                  endWeek: 16, 
                  color: '#2196F3',
                  tableId: _currentTable!.id
                );
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => AddCourseScreenV2(course: null)), 
                );
                if (result != null && result is Course) {
                  result.tableId = _currentTable!.id; // Ensure table ID is set
                  await ScheduleDataService.addCourse(result);
                  _initData();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
        child: const Icon(Icons.today),
        tooltip: '回到本周',
        onPressed: () {
           if (_currentTable != null) {
              int todayWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
              // clamp to valid range
              final targetPage = (todayWeek - 1).clamp(0, _currentTable!.maxWeek - 1);
              _pageController.jumpToPage(targetPage);
           }
        },
      ),
    );
  }

  Widget _buildWeekSchedule(int weekNum) {
    final weekStart = _currentTable!.startDateObj.add(Duration(days: (weekNum - 1) * 7));
    // Correct to Monday if necessary, though logic handled in model ideally
    final adjustedWeekStart = weekStart.subtract(Duration(days: weekStart.weekday - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        final dayColWidth = (constraints.maxWidth - _timeColWidth) / 7;
        
        return Column(
          children: [
            // Header
            SizedBox(
              height: _headerHeight,
              child: Row(
                children: [
                  SizedBox(width: _timeColWidth, child: Center(child: Text("${weekStart.month}\n月", textAlign: TextAlign.center,))),
                  ...List.generate(7, (index) {
                    final date = adjustedWeekStart.add(Duration(days: index));
                    final isToday = DateTime.now().day == date.day && DateTime.now().month == date.month && DateTime.now().year == date.year;
                    return Container(
                      width: dayColWidth,
                      color: isToday ? Colors.blue.withOpacity(0.1) : null,
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
                                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))
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
                               child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                             );
                          }),
                          
                          // Courses for this week
                          ..._courses.where((c) => c.inWeek(weekNum)).map((course) {
                            // Correct day index (1-7) -> (0-6)
                            final dayIndex = course.day - 1;
                            if (dayIndex < 0 || dayIndex > 6) return const SizedBox();
                            
                            // 节次是从1开始的，转为0-based
                            final startNodeIndex = course.startNode - 1;
                            
                            return Positioned(
                              left: dayIndex * dayColWidth,
                              top: startNodeIndex * _cellHeight,
                              width: dayColWidth - 1, // spacing
                              height: course.step * _cellHeight - 1, // spacing
                              child: GestureDetector(
                                onTap: () => _showCourseDetail(context, course),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: course.colorObj,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        course.courseName,
                                        style: TextStyle(
                                          color: Color(_currentTable!.courseTextColor),
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
                                            color: Color(_currentTable!.courseTextColor),
                                            fontSize: 9,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
}
