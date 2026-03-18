class Score {
  final String courseName;
  final double credit; 
  final double gradePoint; 
  final String semester; 
  final String? gaGrade; 
  final bool isEvaluated; 

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

  
  factory Score.fromApiJson(Map<String, dynamic> json, String currentSemesterName) {
    String rawGrade = json['gaGrade'] ?? '';
    bool isEvaluated = true;
    
    
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
