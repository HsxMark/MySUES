import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/academic_import_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restores previous values and removes keys created during a run',
    () async {
      SharedPreferences.setMockInitialValues({
        'schedule_tables': '[{"id":1}]',
        'student_scores': '[{"score":90}]',
        'current_table_id': 1,
        'user_nickname': 'Alice',
      });

      final prefs = await SharedPreferences.getInstance();
      final snapshot = await AcademicImportSnapshot.capture();

      // Simulate a partial extraction writing new data everywhere.
      await prefs.setString('schedule_tables', '[{"id":1},{"id":2}]');
      await prefs.setString('student_scores', '[{"score":60}]');
      await prefs.setInt('current_table_id', 2);
      await prefs.setString('exam_info_list', '[{"courseName":"Math"}]');
      await prefs.setString('user_internal_id', '4242');
      await prefs.remove('user_nickname');

      await snapshot.restore();

      expect(prefs.getString('schedule_tables'), '[{"id":1}]');
      expect(prefs.getString('student_scores'), '[{"score":90}]');
      expect(prefs.getInt('current_table_id'), 1);
      expect(prefs.getString('user_nickname'), 'Alice');
      expect(prefs.containsKey('exam_info_list'), isFalse);
      expect(prefs.containsKey('user_internal_id'), isFalse);
    },
  );

  test('keeps untouched keys out of the restored state', () async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final snapshot = await AcademicImportSnapshot.capture();

    await prefs.setString('last_sync_time_academic', '2026-09-22 12:00');
    await snapshot.restore();

    expect(prefs.containsKey('last_sync_time_academic'), isFalse);
  });
}
