import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';

class ExamService {
  static const String _examsKey = 'exam_info_list';
  
  
  static final ValueNotifier<int> examsUpdateNotifier = ValueNotifier(0);

  static Future<List<Exam>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_examsKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      List<Exam> exams = jsonList.map((e) => Exam.fromJson(e)).toList();
      
      
      bool changed = false;
      final now = DateTime.now();
      
      exams = exams.map((exam) {
        if (exam.status == '已结束') return exam; 

        final endTime = _parseEndTime(exam.timeString);
        if (endTime != null && endTime.isBefore(now)) {
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
      
      return [];
    }
  }

  static DateTime? _parseEndTime(String timeString) {
    
    
    
    
    try {
      final parts = timeString.split(' ');
      if (parts.length < 2) return null; 

      final dateStr = parts[0];
      String timePart = parts[1];
      
      
      if (timePart.contains('~')) {
        timePart = timePart.split('~')[1];
      }
      
      else if (timePart.contains('-')) {
         timePart = timePart.split('-')[1];
      }

      return DateTime.parse('$dateStr $timePart:00');
    } catch (e) {
      
      try {
        if (timeString.length >= 10) {
           
           final dateStr = timeString.substring(0, 10);
           return DateTime.parse('$dateStr 23:59:59');
        }
      } catch (_) {}
      return null;
    }
  }

  static Future<void> saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(exams.map((e) => e.toJson()).toList());
    await prefs.setString(_examsKey, jsonString);
    
    examsUpdateNotifier.value++;
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
    ); 
    await saveExams(exams);
  }

  static Future<void> updateExam(Exam oldExam, Exam newExam) async {
    final exams = await loadExams();
    final index = exams.indexWhere((e) => 
      e.courseName == oldExam.courseName && 
      e.timeString == oldExam.timeString
    );
    
    if (index != -1) {
      exams[index] = newExam;
      await saveExams(exams);
    }
  }

  static Future<void> clearFinishedExams() async {
    final exams = await loadExams();
    exams.removeWhere((e) => e.status == '已结束');
    await saveExams(exams);
  }
}
