import '../models/score.dart';

/// Shared calculations and display formatting for transcript metrics.
abstract final class ScoreMetrics {
  /// Calculates the credit-weighted GPA for evaluated scores only.
  static double calculateGpa(Iterable<Score> scores) {
    var totalPoints = 0.0;
    var totalCredits = 0.0;

    for (final score in scores) {
      if (!score.isEvaluated) continue;

      totalPoints += score.gradePoint * score.credit;
      totalCredits += score.credit;
    }

    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  /// Displays credits with the two decimal places supported by the source.
  static String formatCredits(double credits) => credits.toStringAsFixed(2);

  /// Displays summary GPA to three decimal places.
  static String formatGpa(double gpa) => gpa.toStringAsFixed(3);
}
