import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart';

class ScheduleDataService {
  static const String _tablesKey = 'schedule_tables';
  static const String _coursesKey = 'schedule_courses'; // 新的课程存储Key
  static const String _timeDetailsKey = 'time_details';
  static const String _currentTableIdKey = 'current_table_id';

  // --- ScheduleTable Operations ---

  static Future<List<ScheduleTable>> loadScheduleTables() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tablesKey);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List;
    final tables = jsonList.map((e) => ScheduleTable.fromJson(e)).toList();
    
    // Force upgrade old data that might have default 12 nodes vwhich is undesirable
    bool needsSave = false;
    for (var table in tables) {
      if (table.nodes == 12) {
         table.nodes = 15;
         needsSave = true;
      }
    }
    if (needsSave) {
      final jsonStringNew = jsonEncode(tables.map((e) => e.toJson()).toList());
      await prefs.setString(_tablesKey, jsonStringNew);
    }
    
    return tables;
  }

  static Future<void> saveScheduleTables(List<ScheduleTable> tables) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(tables.map((e) => e.toJson()).toList());
    await prefs.setString(_tablesKey, jsonString);
  }

  static Future<void> addScheduleTable(ScheduleTable table) async {
    final tables = await loadScheduleTables();
    // Simple auto-increment ID logic for demo
    int maxId = 0;
    if (tables.isNotEmpty) {
      maxId = tables.map((e) => e.id).reduce((a, b) => a > b ? a : b);
    }
    table.id = maxId + 1;
    tables.add(table);
    await saveScheduleTables(tables);
  }

  static Future<void> updateScheduleTable(ScheduleTable table) async {
    final tables = await loadScheduleTables();
    final index = tables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      tables[index] = table;
      await saveScheduleTables(tables);
    }
  }

  static Future<void> deleteScheduleTable(int id) async {
    final tables = await loadScheduleTables();
    tables.removeWhere((t) => t.id == id);
    await saveScheduleTables(tables);
    
    // Also delete courses for this table
    final allCourses = await loadCourses();
    allCourses.removeWhere((c) => c.tableId == id);
    await saveCourses(allCourses);
  }
  
  static Future<int> getCurrentTableId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentTableIdKey) ?? 0;
  }
  
  static Future<void> setCurrentTableId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentTableIdKey, id);
  }


  // --- Course Operations ---

  static Future<List<Course>> loadCourses({int? tableId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_coursesKey);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List;
    var courses = jsonList.map((e) => Course.fromJson(e)).toList();
    if (tableId != null) {
      courses = courses.where((c) => c.tableId == tableId).toList();
    }
    return courses;
  }

  static Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(courses.map((e) => e.toJson()).toList());
    await prefs.setString(_coursesKey, jsonString);
  }

  static Future<void> addCourse(Course course) async {
    final allCourses = await loadCourses();
    int maxId = 0;
    if (allCourses.isNotEmpty) {
      maxId = allCourses.map((e) => e.id).reduce((a, b) => a > b ? a : b);
    }
    course.id = maxId + 1;
    allCourses.add(course);
    await saveCourses(allCourses);
  }
  
  static Future<void> updateCourse(Course course) async {
    final allCourses = await loadCourses();
     int index = allCourses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      allCourses[index] = course;
      await saveCourses(allCourses);
    }
  }

  static Future<void> deleteCourse(int courseId) async {
    final allCourses = await loadCourses();
    allCourses.removeWhere((c) => c.id == courseId);
    await saveCourses(allCourses);
  }

  // --- TimeTable Operations ---
  
  static Future<List<TimeDetail>> loadTimeDetails({int? timeTableId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_timeDetailsKey);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List;
    var details = jsonList.map((e) => TimeDetail.fromJson(e)).toList();
    if (timeTableId != null) {
      details = details.where((d) => d.timeTableId == timeTableId).toList();
    }
    details.sort((a, b) => a.node.compareTo(b.node));
    return details;
  }

  static Future<void> saveTimeDetails(List<TimeDetail> details) async {
    final prefs = await SharedPreferences.getInstance();
    // Load all first, then replace/merge. For simplicity assuming full rewrite for now or append.
    // Actually, to update specific table's details, we should load all, remove old for that table, add new.
    // But for initDefaultData, we can just save.
    
    // Better strategy for save:
    // This function assumes 'details' is the ALL list or we read-modify-write.
    // Let's implement read-modify-write for simplicity in usage.
    
    // final allDetails = await loadTimeDetails(); 
    // This is tricky if we want to save a subset. 
    // Let's change this to: save ALL time details.
    
    final jsonString = jsonEncode(details.map((e) => e.toJson()).toList());
    await prefs.setString(_timeDetailsKey, jsonString);
  }
  
  static Future<void> addTimeDetail(TimeDetail detail) async {
    final allDetails = await loadTimeDetails();
    allDetails.add(detail);
    await saveTimeDetails(allDetails);
  }

  // 初始化默认数据
  static Future<void> initDefaultData() async {
    // Check tables
    final tables = await loadScheduleTables();
    if (tables.isEmpty) {
      // 创建默认时间表
      // 1. TimeTable
      // final timeTable = TimeTable(id: 1, name: '默认作息');
      // Save TimeTable (need to impl saveTimeTables if managing multiple, but here just check details)
      
      // 2. Default Details
      final defaultDetails = [
        TimeDetail(node: 1, startTime: '08:15', endTime: '08:55', timeTableId: 1),
        TimeDetail(node: 2, startTime: '08:55', endTime: '09:35', timeTableId: 1),
        TimeDetail(node: 3, startTime: '09:55', endTime: '10:35', timeTableId: 1),
        TimeDetail(node: 4, startTime: '10:35', endTime: '11:15', timeTableId: 1),
        TimeDetail(node: 5, startTime: '11:20', endTime: '12:00', timeTableId: 1),
        TimeDetail(node: 6, startTime: '13:20', endTime: '14:00', timeTableId: 1),
        TimeDetail(node: 7, startTime: '14:00', endTime: '14:40', timeTableId: 1),
        TimeDetail(node: 8, startTime: '15:00', endTime: '15:40', timeTableId: 1),
        TimeDetail(node: 9, startTime: '15:40', endTime: '16:20', timeTableId: 1),
        TimeDetail(node: 10, startTime: '16:35', endTime: '17:15', timeTableId: 1),
        TimeDetail(node: 11, startTime: '17:15', endTime: '17:55', timeTableId: 1),
        TimeDetail(node: 12, startTime: '18:10', endTime: '18:50', timeTableId: 1),
        TimeDetail(node: 13, startTime: '18:50', endTime: '19:30', timeTableId: 1),
        TimeDetail(node: 14, startTime: '19:35', endTime: '20:15', timeTableId: 1),
        TimeDetail(node: 15, startTime: '20:20', endTime: '21:00', timeTableId: 1),
      ];
      
      // Check if time details exist, if not save them
      final existingDetails = await loadTimeDetails();
      if (existingDetails.isEmpty) {
        await saveTimeDetails(defaultDetails);
      }

      // 创建默认课表
      final defaultTable = ScheduleTable(
        tableName: '默认课表',
        startDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).toIso8601String().split('T')[0],
        timeTableId: 1, // Link to default time table
        nodes: 15, // Update to 15
      );
      await addScheduleTable(defaultTable);
      await setCurrentTableId(defaultTable.id);
    }
  }
}
