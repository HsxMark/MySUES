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
  
  int _calculateCurrentWeek(DateTime startDate) {
    // 简单的周次计算逻辑
    // 确保startDate是周一
    final startMonday = startDate.subtract(Duration(days: startDate.weekday - 1));
    final now = DateTime.now();
    final diff = now.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
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
        body: const Center(child: Text('没有课表数据，请先创建课表')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_currentTable!.tableName),
            Text(
              '第 $_currentWeek 周',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              int todayWeek = _calculateCurrentWeek(_currentTable!.startDateObj);
              _pageController.jumpToPage(todayWeek - 1);
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
        child: const Icon(Icons.add),
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
               MaterialPageRoute(builder: (c) => AddCourseScreenV2(course: newCourse)),
             );
             if (result != null && result is Course) {
               result.tableId = _currentTable!.id; // Ensure table ID is set
               await ScheduleDataService.addCourse(result);
               _initData();
             }
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
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (c) => AddCourseScreenV2(course: course)),
                                  );
                                  if (result != null && result is Course) {
                                     await ScheduleDataService.updateCourse(result);
                                     _initData();
                                  }
                                },
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
