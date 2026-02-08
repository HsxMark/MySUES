class Score {
  final String courseName;
  final double credit; // 学分
  final double score; // 分数 (例如 85, 90)
  final double gradePoint; // 绩点 (例如 3.5, 4.0)
  final String semester; // 学期 (例如 "2023-2024-1")
  final String? gaGrade; // 原始成绩字符串 (可能包含 HTML)
  final bool isEvaluated; // 是否已评教

  Score({
    required this.courseName,
    required this.credit,
    required this.score,
    required this.gradePoint,
    required this.semester,
    this.gaGrade,
    this.isEvaluated = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'credit': credit,
      'score': score,
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
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
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
    
    // 尝试解析分数
    // gaGrade 可能是 "85", "A", "良", 或 HTML
    String scoreStr = rawGrade.replaceAll(RegExp(r'<[^>]*>'), ''); // 去除 HTML 标签
    double scoreVal = 0.0;
    
    // 如果未评教，分数设为 0 (或者 -1 表示无效?) 
    // 这里保持 0，但在 UI 上根据 isEvaluated 判断显示
    if (isEvaluated) {
      double? tryParse = double.tryParse(scoreStr);
      if (tryParse != null) {
        scoreVal = tryParse;
      } else {
        // 处理等级制
        if (scoreStr.contains('A')) scoreVal = 95;
        else if (scoreStr.contains('B')) scoreVal = 85;
        else if (scoreStr.contains('C')) scoreVal = 75;
        else if (scoreStr.contains('D')) scoreVal = 65;
        else if (scoreStr.contains('P') || scoreStr.contains('Pass')) scoreVal = 100; // 通过
        // 中文等级 simple mapping
        else if (scoreStr.contains('优')) scoreVal = 95;
        else if (scoreStr.contains('良')) scoreVal = 85;
        else if (scoreStr.contains('中')) scoreVal = 75;
        else if (scoreStr.contains('及')) scoreVal = 65;
      }
    }

    return Score(
      courseName: json['courseName'] ?? '',
      credit: credit,
      score: scoreVal,
      gradePoint: gp,
      semester: json['semesterName'] ?? currentSemesterName, // API returns semesterName usually
      gaGrade: rawGrade, // 保存原始数据以便 UI 使用
      isEvaluated: isEvaluated,
    );
  }
}
