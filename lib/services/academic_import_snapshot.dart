import 'package:shared_preferences/shared_preferences.dart';

import 'exam_service.dart';
import 'score_service.dart';
import 'widget_service.dart';

/// Captures the local state touched by the academic extraction flow so a
/// cancelled run can be rolled back to the state it started from.
class AcademicImportSnapshot {
  AcademicImportSnapshot._(this._values);

  /// Every SharedPreferences key written by the extraction steps.
  static const List<String> trackedKeys = [
    // Schedule tables, courses and semester catalogs.
    'schedule_tables',
    'schedule_courses',
    'semester_course_catalogs',
    'current_table_id',
    // Scores.
    'student_scores',
    'last_import_time',
    'last_import_method',
    // Exams.
    'exam_info_list',
    // Profile.
    'user_nickname',
    'student_id',
    'user_internal_id',
    'user_major',
    'user_college',
    'user_class',
    // Last academic sync timestamp.
    'last_sync_time_academic',
  ];

  final Map<String, Object?> _values;

  static Future<AcademicImportSnapshot> capture() async {
    final prefs = await SharedPreferences.getInstance();
    return AcademicImportSnapshot._({
      for (final key in trackedKeys) key: prefs.get(key),
    });
  }

  /// Restores every tracked key to its captured value. Keys that did not exist
  /// before the run are removed again.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in trackedKeys) {
      final value = _values[key];
      if (value == null) {
        await prefs.remove(key);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }

    // Keep the home widget and listeners in sync with the restored data.
    await WidgetService.updateWidget();
    ScoreService.updateNotifier.value++;
    ExamService.examsUpdateNotifier.value++;
  }
}
