import 'package:flutter/material.dart';
import 'screens/curriculum_screen.dart';
import 'models/course_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的课表',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: CurriculumScreen(courseList: _generateSampleCourses()),
      debugShowCheckedModeBanner: false,
    );
  }

  /// 生成示例课程数据
  List<CourseItem> _generateSampleCourses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return [
      // 周一课程
      CourseItem(
        title: '高等数学',
        type: '必修',
        location: '教学楼A101',
        startTime: weekStart.add(const Duration(hours: 8)),
        endTime: weekStart.add(const Duration(hours: 9, minutes: 30)),
        count: 2,
        color: Colors.blue[200]!,
      ),
      CourseItem(
        title: '大学英语',
        type: '必修',
        location: '教学楼B201',
        startTime: weekStart.add(const Duration(hours: 10, minutes: 30)),
        endTime: weekStart.add(const Duration(hours: 12)),
        count: 2,
        color: Colors.green[200]!,
      ),
      
      // 周二课程
      CourseItem(
        title: '数据结构',
        type: '必修',
        location: '实验楼C302',
        startTime: weekStart.add(const Duration(days: 1, hours: 8, minutes: 50)),
        endTime: weekStart.add(const Duration(days: 1, hours: 10, minutes: 20)),
        count: 2,
        color: Colors.orange[200]!,
      ),
      CourseItem(
        title: '计算机网络',
        type: '必修',
        location: '教学楼A305',
        startTime: weekStart.add(const Duration(days: 1, hours: 14, minutes: 20)),
        endTime: weekStart.add(const Duration(days: 1, hours: 16, minutes: 40)),
        count: 3,
        color: Colors.purple[200]!,
      ),
      
      // 周三课程
      CourseItem(
        title: '操作系统',
        type: '必修',
        location: '教学楼D401',
        startTime: weekStart.add(const Duration(days: 2, hours: 8)),
        endTime: weekStart.add(const Duration(days: 2, hours: 9, minutes: 30)),
        count: 2,
        color: Colors.pink[200]!,
      ),
      CourseItem(
        title: '软件工程',
        type: '选修',
        location: '教学楼B103',
        startTime: weekStart.add(const Duration(days: 2, hours: 13, minutes: 30)),
        endTime: weekStart.add(const Duration(days: 2, hours: 15)),
        count: 2,
        color: Colors.teal[200]!,
      ),
      
      // 周四课程
      CourseItem(
        title: '算法设计',
        type: '必修',
        location: '实验楼C205',
        startTime: weekStart.add(const Duration(days: 3, hours: 9, minutes: 40)),
        endTime: weekStart.add(const Duration(days: 3, hours: 11, minutes: 10)),
        count: 2,
        color: Colors.amber[200]!,
      ),
      
      // 周五课程
      CourseItem(
        title: '数据库原理',
        type: '必修',
        location: '教学楼A202',
        startTime: weekStart.add(const Duration(days: 4, hours: 8)),
        endTime: weekStart.add(const Duration(days: 4, hours: 10, minutes: 20)),
        count: 3,
        color: Colors.cyan[200]!,
      ),
      CourseItem(
        title: 'Web开发技术',
        type: '选修',
        location: '实验楼D501',
        startTime: weekStart.add(const Duration(days: 4, hours: 14, minutes: 20)),
        endTime: weekStart.add(const Duration(days: 4, hours: 16, minutes: 40)),
        count: 3,
        color: Colors.lime[200]!,
      ),
    ];
  }
}
