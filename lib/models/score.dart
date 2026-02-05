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

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'credit': credit,
      'score': score,
      'gradePoint': gradePoint,
      'semester': semester,
    };
  }

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      courseName: json['courseName'] ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 0.0,
      semester: json['semester'] ?? '',
    );
  }
}
