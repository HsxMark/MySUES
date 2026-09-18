import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/student_info.dart';

void main() {
  group('StudentInfoHelper.calculateGradeNumber', () {
    const studentId = '021123001';

    test('uses the current academic year before September', () {
      expect(
        StudentInfoHelper.calculateGradeNumber(
          studentId,
          now: DateTime(2026, 8, 31),
        ),
        3,
      );
    });

    test('advances the year of study in September', () {
      expect(
        StudentInfoHelper.calculateGradeNumber(
          studentId,
          now: DateTime(2026, 9, 1),
        ),
        4,
      );
    });

    test('returns zero for an invalid student ID', () {
      expect(
        StudentInfoHelper.calculateGradeNumber(
          'invalid',
          now: DateTime(2026, 9, 1),
        ),
        0,
      );
    });

    test('returns zero for a partial student ID', () {
      expect(
        StudentInfoHelper.calculateGradeNumber(
          '021123',
          now: DateTime(2026, 9, 1),
        ),
        0,
      );
    });
  });

  test('parseStudentId uses the supplied date for the grade label', () {
    expect(
      StudentInfoHelper.parseStudentId(
        '021123001',
        now: DateTime(2026, 9, 1),
      )['grade'],
      '大四',
    );
  });
}
