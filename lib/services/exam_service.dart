import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';

class ExamService {
  static const String _examsKey = 'exam_info_list';

  static Future<List<Exam>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_examsKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((e) => Exam.fromJson(e)).toList();
    } catch (e) {
      // Handle legacy or corrupted data
      return [];
    }
  }

  static Future<void> saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(exams.map((e) => e.toJson()).toList());
    await prefs.setString(_examsKey, jsonString);
  }

  static Future<void> addExam(Exam exam) async {
    final exams = await loadExams();
    exams.add(exam);
    await saveExams(exams);
  }

  static Future<void> deleteExam(Exam exam) async {
    final exams = await loadExams();
    exams.removeWhere((e) => 
      e.courseName == exam.courseName && 
      e.timeString == exam.timeString
    ); // Simple matching strategy
    await saveExams(exams);
  }

  static Future<void> clearFinishedExams() async {
    final exams = await loadExams();
    exams.removeWhere((e) => e.status == '已结束');
    await saveExams(exams);
  }
}
