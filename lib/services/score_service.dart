import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score.dart';

class ScoreService {
  static const String _scoresKey = 'student_scores';
  static const String _lastImportTimeKey = 'last_import_time';
  static const String _lastImportMethodKey = 'last_import_method';

  static Future<List<Score>> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_scoresKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((e) => Score.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveScores(List<Score> scores) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(scores.map((e) => e.toJson()).toList());
    await prefs.setString(_scoresKey, jsonString);
  }

  static Future<Map<String, String?>> loadImportInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'time': prefs.getString(_lastImportTimeKey),
      'method': prefs.getString(_lastImportMethodKey),
    };
  }

  static Future<void> saveImportInfo(String time, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastImportTimeKey, time);
    await prefs.setString(_lastImportMethodKey, method);
  }

  static Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
    await prefs.remove(_lastImportTimeKey);
    await prefs.remove(_lastImportMethodKey);
  }
}
