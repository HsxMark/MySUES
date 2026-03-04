class Score {
  final String courseName;
  final double credit; // 学分
  final double gradePoint; // 绩点 (例如 3.5, 4.0)
  final String semester; // 学期 (例如 "2023-2024-1")
  final String? gaGrade; // 原始成绩字符串 (可能包含 HTML)
  final bool isEvaluated; // 是否已评教

  Score({
    required this.courseName,
    required this.credit,
    required this.gradePoint,
    required this.semester,
    this.gaGrade,
    this.isEvaluated = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'credit': credit,
      'gradePoint': gradePoint,
      'semester': semester,
      'gaGrade': gaGrade,
      'isEvaluated': isEvaluated,
    };
  }

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      courseName: json['courseName'] ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 0.0,
      semester: json['semester'] ?? '',
      gaGrade: json['gaGrade'],
      isEvaluated: json['isEvaluated'] ?? true,
    );
  }

  /// 从 API JSON 解析 (参考 example/score.json)
  factory Score.fromApiJson(Map<String, dynamic> json, String currentSemesterName) {
    String rawGrade = json['gaGrade'] ?? '';
    bool isEvaluated = true;
    
    // 检查是否包含 "请先完成评教"
    if (rawGrade.contains('请先完成评教') || rawGrade.contains('评教')) {
      isEvaluated = false;
    }

    double gp = (json['gp'] as num?)?.toDouble() ?? 0.0;
    double credit = (json['credits'] as num?)?.toDouble() ?? 0.0;

    return Score(
      courseName: json['courseName'] ?? '',
      credit: credit,
      gradePoint: gp,
      semester: json['semesterName'] ?? currentSemesterName,
      gaGrade: rawGrade,
      isEvaluated: isEvaluated,
    );
  }
}
