import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this for ValueNotifier
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';
import '../utils/exam_status.dart';

class ExamService {
  static const String _examsKey = 'exam_info_list';

  // Notifier to alert UI of updates
  static final ValueNotifier<int> examsUpdateNotifier = ValueNotifier(0);

  static Future<List<Exam>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_examsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      List<Exam> exams = jsonList.map((e) => Exam.fromJson(e)).toList();

      // Auto-update status based on time
      bool changed = false;
      final now = DateTime.now();

      exams = exams.map((exam) {
        if (isFinishedExamStatus(exam.status)) return exam; // Already finished

        final endTime = parseExamEndTime(exam.timeString);
        if (endTime != null && !endTime.isAfter(now)) {
          changed = true;
          return Exam(
            courseName: exam.courseName,
            timeString: exam.timeString,
            location: exam.location,
            type: exam.type,
            status: '已结束',
          );
        }
        return exam;
      }).toList();

      if (changed) {
        await saveExams(exams);
      }

      return exams;
    } catch (e) {
      // Handle legacy or corrupted data
      return [];
    }
  }

  static Future<void> saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(exams.map((e) => e.toJson()).toList());
    await prefs.setString(_examsKey, jsonString);
    // Notify listeners
    examsUpdateNotifier.value++;
  }

  static Future<void> addExam(Exam exam) async {
    final exams = await loadExams();
    exams.add(exam);
    await saveExams(exams);
  }

  static Future<void> deleteExam(Exam exam) async {
    final exams = await loadExams();
    exams.removeWhere(
      (e) => e.courseName == exam.courseName && e.timeString == exam.timeString,
    ); // Simple matching strategy
    await saveExams(exams);
  }

  static Future<void> updateExam(Exam oldExam, Exam newExam) async {
    final exams = await loadExams();
    final index = exams.indexWhere(
      (e) =>
          e.courseName == oldExam.courseName &&
          e.timeString == oldExam.timeString,
    );

    if (index != -1) {
      exams[index] = newExam;
      await saveExams(exams);
    }
  }

  static Future<void> clearFinishedExams() async {
    final exams = await loadExams();
    exams.removeWhere((e) => isFinishedExamStatus(e.status));
    await saveExams(exams);
  }
}
