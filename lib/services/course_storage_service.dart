import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_item.dart';

/// 课程存储服务
class CourseStorageService {
  static const String _coursesKey = 'user_courses';

  /// 保存课程列表
  static Future<void> saveCourses(List<CourseItem> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = courses.map((course) => course.toJson()).toList();
    await prefs.setString(_coursesKey, jsonEncode(jsonList));
  }

  /// 加载课程列表
  static Future<List<CourseItem>> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_coursesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CourseItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('加载课程数据失败: $e');
      return [];
    }
  }

  /// 添加课程
  static Future<void> addCourse(CourseItem course) async {
    final courses = await loadCourses();
    courses.add(course);
    await saveCourses(courses);
  }

  /// 删除课程
  static Future<void> deleteCourse(int index) async {
    final courses = await loadCourses();
    if (index >= 0 && index < courses.length) {
      courses.removeAt(index);
      await saveCourses(courses);
    }
  }

  /// 更新课程
  static Future<void> updateCourse(int index, CourseItem course) async {
    final courses = await loadCourses();
    if (index >= 0 && index < courses.length) {
      courses[index] = course;
      await saveCourses(courses);
    }
  }

  /// 清空所有课程
  static Future<void> clearAllCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesKey);
  }
}
