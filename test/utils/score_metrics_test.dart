import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/score.dart';
import 'package:mysues/utils/score_metrics.dart';

void main() {
  group('ScoreMetrics', () {
    test('formats credits with exactly two decimal places', () {
      expect(ScoreMetrics.formatCredits(0.25), '0.25');
      expect(ScoreMetrics.formatCredits(1.5), '1.50');
      expect(ScoreMetrics.formatCredits(2), '2.00');
    });

    test('formats GPA with three decimal places', () {
      expect(ScoreMetrics.formatGpa(3.3746), '3.375');
      expect(ScoreMetrics.formatGpa(0), '0.000');
    });

    test(
      'calculates credit-weighted GPA without excluding fractional credits',
      () {
        final scores = [
          Score(
            courseName: 'Quarter credit',
            credit: 0.25,
            gradePoint: 4,
            semester: '2025-1',
          ),
          Score(
            courseName: 'Two credits',
            credit: 2,
            gradePoint: 3.7,
            semester: '2025-1',
          ),
        ];

        expect(ScoreMetrics.calculateGpa(scores), closeTo(3.7333333333, 1e-10));
      },
    );

    test(
      'excludes unevaluated scores from GPA and zero-credit input returns zero',
      () {
        final pending = Score(
          courseName: 'Pending',
          credit: 3,
          gradePoint: 4,
          semester: '2025-1',
          isEvaluated: false,
        );

        expect(ScoreMetrics.calculateGpa([pending]), 0);
        expect(ScoreMetrics.calculateGpa(const []), 0);
      },
    );
  });
}
