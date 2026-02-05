import 'package:flutter/material.dart';
import '../models/course_item.dart';
import '../services/course_storage_service.dart';
import 'add_course_screen.dart';
import 'semester_settings_screen.dart';

/// 主课程表界面（直接显示课程表）
class MainScheduleScreen extends StatefulWidget {
  const MainScheduleScreen({super.key});

  @override
  State<MainScheduleScreen> createState() => _MainScheduleScreenState();
}

class _MainScheduleScreenState extends State<MainScheduleScreen> {
  late PageController _pageController;
  late DateTime _currentWeekStart;
  int _currentPage = 1000;
  List<CourseItem> _baseCourses = [];
  bool _isLoading = true;
  DateTime? _semesterStartDate; // 学期开始日期

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _pageController = PageController(initialPage: _currentPage);
    _loadCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 加载课程
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    final courses = await CourseStorageService.loadCourses();
    final semesterStart = await CourseStorageService.loadSemesterStartDate();

    setState(() {
      _baseCourses = courses;
      _semesterStartDate = semesterStart;
      _isLoading = false;
    });
  }

  /// 获取某个日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 获取当前页面对应的周开始日期
  DateTime _getPageWeekStart() {
    final weekOffset = _currentPage - 1000;
    return _currentWeekStart.add(Duration(days: weekOffset * 7));
  }

  /// 生成所有周次的课程实例
  List<CourseItem> _generateAllCourseInstances() {
    final List<CourseItem> allInstances = [];

    if (_semesterStartDate == null) {
      // 如果没有设置学期开始日期，使用默认逻辑
      return allInstances;
    }

    for (var course in _baseCourses) {
      if (course.weekNumbers.isEmpty) continue;

      for (var weekNumber in course.weekNumbers) {
        // 计算该周次的周一日期
        final weekMonday = _semesterStartDate!.add(
          Duration(days: (weekNumber - 1) * 7),
        );

        // 根据课程设置的星期几，计算具体日期
        final courseWeekday = course.startTime.weekday; // 1=周一, 7=周日
        final courseDate = weekMonday.add(Duration(days: courseWeekday - 1));

        final instance = CourseItem(
          title: course.title,
          type: course.type,
          location: course.location,
          teacher: course.teacher,
          startTime: DateTime(
            courseDate.year,
            courseDate.month,
            courseDate.day,
            course.startTime.hour,
            course.startTime.minute,
          ),
          endTime: DateTime(
            courseDate.year,
            courseDate.month,
            courseDate.day,
            course.endTime.hour,
            course.endTime.minute,
          ),
          count: course.count,
          color: course.color,
          weekNumbers: [weekNumber],
        );

        allInstances.add(instance);
      }
    }

    return allInstances;
  }

  /// 获取当前周数（基于学期开始日期）
  int _getCurrentWeekNumber() {
    if (_semesterStartDate == null) {
      // 如果没有设置学期开始日期，返回1
      return 1;
    }

    final now = DateTime.now();
    final daysSinceStart = now.difference(_semesterStartDate!).inDays;
    final weekNumber = (daysSinceStart / 7).floor() + 1;

    // 限制在1-20周范围内
    if (weekNumber < 1) return 1;
    if (weekNumber > 20) return 20;
    return weekNumber;
  }

  /// 计算周数（基于学期开始日期）
  int _getWeekNumber(DateTime date) {
    if (_semesterStartDate == null) {
      return 1;
    }

    final daysSinceStart = date.difference(_semesterStartDate!).inDays;
    final weekNumber = (daysSinceStart / 7).floor() + 1;

    // 限制在1-20周范围内
    if (weekNumber < 1) return 1;
    if (weekNumber > 20) return 20;
    return weekNumber;
  }

  /// 添加课程
  Future<void> _addCourse() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddCourseScreen()),
    );

    if (result != null && result['course'] != null) {
      await CourseStorageService.addCourse(result['course']);
      await _loadCourses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('课程已添加')));
      }
    }
  }

  /// 显示课程列表管理
  void _showCourseManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '课程管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _baseCourses.isEmpty
                    ? const Center(child: Text('还没有添加任何课程'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _baseCourses.length,
                        itemBuilder: (context, index) {
                          final course = _baseCourses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: course.color,
                                child: Text(
                                  course.type.isNotEmpty ? course.type[0] : '课',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              title: Text(
                                course.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (course.teacher.isNotEmpty)
                                    Text('👨‍🏫 ${course.teacher}'),
                                  if (course.location.isNotEmpty)
                                    Text('📍 ${course.location}'),
                                  Text(
                                    '📅 周次: ${_formatWeekNumbers(course.weekNumbers)}',
                                  ),
                                  Text('⏰ ${_formatCourseTime(course)}'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  Navigator.pop(context);
                                  if (value == 'edit') {
                                    await _editCourse(index);
                                  } else if (value == 'delete') {
                                    await _deleteCourse(index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('编辑'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('删除'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 编辑课程
  Future<void> _editCourse(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddCourseScreen(course: _baseCourses[index], courseIndex: index),
      ),
    );

    if (result != null && result['course'] != null && result['index'] != null) {
      await CourseStorageService.updateCourse(
        result['index'],
        result['course'],
      );
      await _loadCourses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('课程已更新')));
      }
    }
  }

  /// 删除课程
  Future<void> _deleteCourse(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除课程"${_baseCourses[index].title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CourseStorageService.deleteCourse(index);
      await _loadCourses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('课程已删除')));
      }
    }
  }

  /// 格式化周次显示
  String _formatWeekNumbers(List<int> weeks) {
    if (weeks.isEmpty) return '未设置';
    if (weeks.length <= 3) return weeks.join(', ');
    return '${weeks.first}-${weeks.last}周等';
  }

  /// 格式化课程时间
  String _formatCourseTime(CourseItem course) {
    final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[course.startTime.weekday];
    final startTime =
        '${course.startTime.hour.toString().padLeft(2, '0')}:${course.startTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${course.endTime.hour.toString().padLeft(2, '0')}:${course.endTime.minute.toString().padLeft(2, '0')}';

    return '$weekday $startTime-$endTime (${course.count}节)';
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getPageWeekStart();
    final weekNumber = _getWeekNumber(weekStart);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('我的课表'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allCourses = _generateAllCourseInstances();

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
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showCourseManagement,
            tooltip: '课程管理',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'semester_settings') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SemesterSettingsScreen(),
                  ),
                );
                await _loadCourses(); // 重新加载以更新周次
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'semester_settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('学期设置'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: allCourses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '还没有添加任何课程',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (_semesterStartDate == null) ...[
                    Text(
                      '建议先设置学期开始日期',
                      style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SemesterSettingsScreen(),
                          ),
                        );
                        await _loadCourses();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('设置学期'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '点击右下角按钮添加课程',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : PageView.builder(
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
                  allCourses: allCourses,
                  onRefresh: _loadCourses,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        tooltip: '添加课程',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 单周课程表页面
class WeekSchedulePage extends StatelessWidget {
  final DateTime baseDate;
  final List<CourseItem> allCourses;
  final VoidCallback? onRefresh;

  const WeekSchedulePage({
    super.key,
    required this.baseDate,
    required this.allCourses,
    this.onRefresh,
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
