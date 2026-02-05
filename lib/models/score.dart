class Score {
  final String courseName;
  final double credit; // 学分
  final double score; // 分数 (例如 85, 90)
  final double gradePoint; // 绩点 (例如 3.5, 4.0)
  final String semester; // 学期 (例如 "2023-2024-1")

  Score({
    required this.courseName,
    required this.credit,
    required this.score,
    required this.gradePoint,
    required this.semester,
  });
}
