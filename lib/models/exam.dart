class Exam {
  final String courseName;
  final String timeString; 
  final String location;
  final String type; 
  final String status; 

  Exam({
    required this.courseName,
    required this.timeString,
    required this.location,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'timeString': timeString,
      'location': location,
      'type': type,
      'status': status,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      courseName: json['courseName'] ?? '',
      timeString: json['timeString'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
