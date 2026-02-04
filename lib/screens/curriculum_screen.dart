import 'package:flutter/material.dart';
import '../models/course_item.dart';

/// 课程表屏幕
class CurriculumScreen extends StatefulWidget {
  final List<CourseItem> courseList;

  const CurriculumScreen({super.key, required this.courseList});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  late PageController _pageController;
  late DateTime _currentWeekStart;
  int _currentPage = 1000; // 从中间开始，允许前后翻页

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 获取某个日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 获取当前页面对应的周开始日期
  DateTime _getPageWeekStart() {
    final weekOffset = _currentPage - 1000;
    return _currentWeekStart.add(Duration(days: weekOffset * 7));
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getPageWeekStart();
    final weekNumber = _getWeekNumber(weekStart);

    return Scaffold(
      appBar: AppBar(
        title: Text('${weekStart.year} 年第 $weekNumber 周'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _currentPage = 1000;
                _pageController.jumpToPage(_currentPage);
              });
            },
            tooltip: '回到本周',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final weekOffset = index - 1000;
          final pageWeekStart = _currentWeekStart.add(
            Duration(days: weekOffset * 7),
          );
          return WeekSchedulePage(
            baseDate: pageWeekStart,
            allCourses: widget.courseList,
          );
        },
      ),
    );
  }

  /// 计算周数（简化版本，使用年内周数）
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}

/// 单周课程表页面
class WeekSchedulePage extends StatelessWidget {
  final DateTime baseDate;
  final List<CourseItem> allCourses;

  const WeekSchedulePage({
    super.key,
    required this.baseDate,
    required this.allCourses,
  });

  /// 标准时间段配置（纵向时间轴，1-15节）
  static const List<TimeSlot> standardTimeSlots = [
    TimeSlot(hour: 8, minute: 15, label: '08:15\n08:55'), // 1节
    TimeSlot(hour: 8, minute: 55, label: '08:55\n09:35'), // 2节
    TimeSlot(hour: 9, minute: 55, label: '09:55\n10:35'), // 3节
    TimeSlot(hour: 10, minute: 35, label: '10:35\n11:15'), // 4节
    TimeSlot(hour: 11, minute: 20, label: '11:20\n12:00'), // 5节
    TimeSlot(hour: 13, minute: 20, label: '13:20\n14:00'), // 6节
    TimeSlot(hour: 14, minute: 0, label: '14:00\n14:40'), // 7节
    TimeSlot(hour: 15, minute: 0, label: '15:00\n15:40'), // 8节
    TimeSlot(hour: 15, minute: 40, label: '15:40\n16:20'), // 9节
    TimeSlot(hour: 16, minute: 35, label: '16:35\n17:15'), // 10节
    TimeSlot(hour: 17, minute: 15, label: '17:15\n17:55'), // 11节
    TimeSlot(hour: 18, minute: 10, label: '18:10\n18:50'), // 12节
    TimeSlot(hour: 18, minute: 50, label: '18:50\n19:30'), // 13节
    TimeSlot(hour: 19, minute: 35, label: '19:35\n20:15'), // 14节
    TimeSlot(hour: 20, minute: 20, label: '20:20\n21:00'), // 15节
  ];

  @override
  Widget build(BuildContext context) {
    final weekDates = List.generate(
      7,
      (index) => baseDate.add(Duration(days: index)),
    );
    final today = DateTime.now();

    // 筛选本周课程
    final weekCourses = allCourses.where((course) {
      final courseDate = DateTime(
        course.startTime.year,
        course.startTime.month,
        course.startTime.day,
      );
      final endOfWeek = baseDate.add(const Duration(days: 6));
      return !courseDate.isBefore(baseDate) && !courseDate.isAfter(endOfWeek);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double timeColWidth = 50;
        final double dayColWidth = (constraints.maxWidth - timeColWidth) / 7;
        const double headerHeight = 60;
        const double cellHeight = 70;

        return Column(
          children: [
            // 表头：日期和星期
            _buildHeader(
              context,
              weekDates,
              today,
              timeColWidth,
              dayColWidth,
              headerHeight,
            ),

            // 课程表主体
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间列
                    _buildTimeColumn(timeColWidth, cellHeight),

                    // 课程网格
                    SizedBox(
                      width: constraints.maxWidth - timeColWidth,
                      child: _buildCourseGrid(
                        context,
                        weekDates,
                        weekCourses,
                        dayColWidth,
                        cellHeight,
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

  /// 构建表头
  Widget _buildHeader(
    BuildContext context,
    List<DateTime> weekDates,
    DateTime today,
    double timeColWidth,
    double dayColWidth,
    double headerHeight,
  ) {
    final monthNames = [
      '',
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 左上角月份标识
          SizedBox(
            width: timeColWidth,
            child: Center(
              child: Text(
                monthNames[baseDate.month],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 星期标题
          ...List.generate(7, (index) {
            final date = weekDates[index];
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return Container(
              width: dayColWidth,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建时间列
  Widget _buildTimeColumn(double width, double cellHeight) {
    return SizedBox(
      width: width,
      child: Column(
        children: standardTimeSlots.map((slot) {
          return Container(
            height: cellHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                slot.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, height: 1.2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建课程网格
  Widget _buildCourseGrid(
    BuildContext context,
    List<DateTime> weekDates,
    List<CourseItem> weekCourses,
    double dayColWidth,
    double cellHeight,
  ) {
    return Stack(
      children: [
        // 背景网格
        Row(
          children: List.generate(7, (dayIndex) {
            return Container(
              width: dayColWidth,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 0.5),
                ),
              ),
              child: Column(
                children: List.generate(standardTimeSlots.length, (slotIndex) {
                  return Container(
                    height: cellHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),

        // 课程卡片叠加层
        ...weekCourses.map((course) {
          return _buildCourseCard(
            context,
            course,
            weekDates,
            dayColWidth,
            cellHeight,
          );
        }),
      ],
    );
  }

  /// 构建单个课程卡片
  Widget _buildCourseCard(
    BuildContext context,
    CourseItem course,
    List<DateTime> weekDates,
    double dayColWidth,
    double cellHeight,
  ) {
    // 计算课程是星期几 (0-6)
    final courseDate = DateTime(
      course.startTime.year,
      course.startTime.month,
      course.startTime.day,
    );

    int dayIndex = -1;
    for (int i = 0; i < weekDates.length; i++) {
      final weekDate = DateTime(
        weekDates[i].year,
        weekDates[i].month,
        weekDates[i].day,
      );
      if (courseDate.isAtSameMomentAs(weekDate)) {
        dayIndex = i;
        break;
      }
    }

    if (dayIndex == -1) return const SizedBox.shrink();

    // 查找开始时间段
    int startSlot = -1;
    final courseTime = TimeOfDay(
      hour: course.startTime.hour,
      minute: course.startTime.minute,
    );

    for (int i = 0; i < standardTimeSlots.length; i++) {
      final slot = standardTimeSlots[i];
      if (courseTime.hour == slot.hour &&
          courseTime.minute >= slot.minute &&
          courseTime.minute < slot.minute + 40) {
        startSlot = i;
        break;
      }
    }

    if (startSlot == -1) {
      // 容错：找最接近的时间段
      for (int i = 0; i < standardTimeSlots.length; i++) {
        if (standardTimeSlots[i].hour == courseTime.hour) {
          startSlot = i;
          break;
        }
      }
    }

    if (startSlot == -1) return const SizedBox.shrink();

    // 计算位置和大小
    final left = dayColWidth * dayIndex;
    final top = cellHeight * startSlot;
    final height = cellHeight * course.count;

    return Positioned(
      left: left + 1,
      top: top + 1,
      child: GestureDetector(
        onTap: () => _showCourseDetailsDialog(context, course),
        child: SizedBox(
          width: dayColWidth - 2,
          height: height - 2,
          child: Card(
            color: course.color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '(${course.type.length > 2 ? course.type.substring(0, 2) : course.type}) ${course.title}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${course.location}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 显示课程详情对话框
void _showCourseDetailsDialog(BuildContext context, CourseItem course) {
  final startTime =
      '${course.startTime.hour.toString().padLeft(2, '0')}:${course.startTime.minute.toString().padLeft(2, '0')}';
  final endTime =
      '${course.endTime.hour.toString().padLeft(2, '0')}:${course.endTime.minute.toString().padLeft(2, '0')}';
  final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final weekday = weekdays[course.startTime.weekday];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(course.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseInfoRow(Icons.category, '类型', course.type),
            if (course.teacher.isNotEmpty)
              _buildCourseInfoRow(Icons.person, '教师', course.teacher),
            _buildCourseInfoRow(
              Icons.location_on,
              '地点',
              course.location.isNotEmpty ? course.location : '未设置',
            ),
            _buildCourseInfoRow(Icons.calendar_today, '星期', weekday),
            _buildCourseInfoRow(
              Icons.access_time,
              '时间',
              '$startTime - $endTime',
            ),
            _buildCourseInfoRow(Icons.timer, '节数', '${course.count}节'),
            if (course.weekNumbers.isNotEmpty)
              _buildCourseInfoRow(
                Icons.date_range,
                '周次',
                course.weekNumbers.join(', '),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

/// 构建课程信息行
Widget _buildCourseInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

/// 时间段模型
class TimeSlot {
  final int hour;
  final int minute;
  final String label;

  const TimeSlot({
    required this.hour,
    required this.minute,
    required this.label,
  });
}
