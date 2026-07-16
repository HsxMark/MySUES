import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/utils/course_credit_formatter.dart';

void main() {
  test('total credits keep two decimals without rounding', () {
    expect(formatTotalCredits(6.25), '6.25');
    expect(formatTotalCredits(6), '6.00');
    expect(formatTotalCredits(6.259), '6.25');
  });

  test('course values remain concise while preserving fractional credits', () {
    expect(formatCourseCredits(2), '2');
    expect(formatCourseCredits(0.25), '0.25');
    expect(formatCourseNumber(60.0), '60');
  });
}
