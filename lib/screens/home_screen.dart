import 'package:flutter/material.dart';
import '../models/course_item.dart';
import '../services/course_storage_service.dart';
import 'curriculum_screen.dart';
import 'add_course_screen.dart';

/// 首页，包含课程列表管理
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CourseItem> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// 加载课程
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    final courses = await CourseStorageService.loadCourses();

    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  /// 生成所有周次的课程实例
  List<CourseItem> _generateAllCourseInstances() {
    final List<CourseItem> allInstances = [];

    for (var course in _courses) {
      if (course.weekNumbers.isEmpty) continue;

      // 为每个周次生成课程实例
      for (var weekNumber in course.weekNumbers) {
        // 计算该周次对应的日期
        final weekOffset = weekNumber - _getCurrentWeekNumber();
        final targetDate = course.startTime.add(Duration(days: weekOffset * 7));

        // 创建该周的课程实例
        final instance = CourseItem(
          title: course.title,
          type: course.type,
          location: course.location,
          teacher: course.teacher,
          startTime: DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            course.startTime.hour,
            course.startTime.minute,
          ),
          endTime: DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
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

  /// 获取当前周数
  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysSinceFirstDay = now.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
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

  /// 编辑课程
  Future<void> _editCourse(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddCourseScreen(course: _courses[index], courseIndex: index),
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
        content: Text('确定要删除课程"${_courses[index].title}"吗？'),
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

  /// 查看课程表
  void _viewSchedule() {
    final allInstances = _generateAllCourseInstances();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurriculumScreen(courseList: allInstances),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的课表'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_courses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.calendar_view_week),
              onPressed: _viewSchedule,
              tooltip: '查看课程表',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要删除所有课程吗？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          '清空',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await CourseStorageService.clearAllCourses();
                  await _loadCourses();

                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('所有课程已清空')));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清空所有课程'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? _buildEmptyState()
          : _buildCourseList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        tooltip: '添加课程',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
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
          Text(
            '点击右下角按钮添加课程',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 课程列表
  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.teacher.isNotEmpty) Text('👨‍🏫 ${course.teacher}'),
                if (course.location.isNotEmpty) Text('📍 ${course.location}'),
                Text('📅 周次: ${_formatWeekNumbers(course.weekNumbers)}'),
                Text('⏰ ${_formatCourseTime(course)}'),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editCourse(index);
                } else if (value == 'delete') {
                  _deleteCourse(index);
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
    );
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
}
