import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/utils/exam_status.dart';

void main() {
  group('examStatusForEndTime', () {
    final now = DateTime(2026, 7, 18, 12);

    test('returns unfinished when the end time is in the future', () {
      expect(
        examStatusForEndTime(DateTime(2026, 7, 18, 12, 1), now: now),
        '未结束',
      );
    });

    test('returns finished when the end time is in the past', () {
      expect(
        examStatusForEndTime(DateTime(2026, 7, 18, 11, 59), now: now),
        '已结束',
      );
    });

    test('returns finished when the end time equals now', () {
      expect(examStatusForEndTime(now, now: now), '已结束');
    });
  });

  group('parseExamEndTime', () {
    test('parses a same-day range', () {
      expect(
        parseExamEndTime('2026-07-18 08:15~10:15'),
        DateTime(2026, 7, 18, 10, 15),
      );
    });

    test('parses a cross-day range', () {
      expect(
        parseExamEndTime('2026-07-18 23:30~2026-07-19 01:00'),
        DateTime(2026, 7, 19, 1),
      );
    });

    test('parses a legacy single date-time', () {
      expect(
        parseExamEndTime('2026-07-18 10:15'),
        DateTime(2026, 7, 18, 10, 15),
      );
    });

    test('parses a legacy range separated by a dash', () {
      expect(
        parseExamEndTime('2026-07-18 08:15 - 10:15'),
        DateTime(2026, 7, 18, 10, 15),
      );
    });

    test('parses a legacy compact range separated by a dash', () {
      expect(
        parseExamEndTime('2026-07-18 08:15-10:15'),
        DateTime(2026, 7, 18, 10, 15),
      );
    });

    test('returns null for an invalid value', () {
      expect(parseExamEndTime('invalid'), isNull);
    });
  });
}
