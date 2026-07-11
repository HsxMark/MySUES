import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score.dart';

class ScoreService {
  static const String _scoresKey = 'student_scores';
  static const String _lastImportTimeKey = 'last_import_time';
  static const String _legacyLastImportMethodKey = 'last_import_method';

  /// Notifies listeners when scores are updated (saved or cleared).
  static final ValueNotifier<int> updateNotifier = ValueNotifier(0);

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
    updateNotifier.value++;
  }

  static Future<String?> loadLastImportTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyLastImportMethodKey);
    return prefs.getString(_lastImportTimeKey);
  }

  static Future<void> saveLastImportTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastImportTimeKey, time);
    await prefs.remove(_legacyLastImportMethodKey);
  }

  static Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
    await prefs.remove(_lastImportTimeKey);
    await prefs.remove(_legacyLastImportMethodKey);
    updateNotifier.value++;
  }
}
