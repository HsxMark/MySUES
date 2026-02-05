class Exam {
  final String courseName;
  final String timeString; // e.g., "2025-09-05 08:15" or range
  final String location;
  final String type; // e.g., "补考", "期末"
  final String status; // e.g., "已结束", "进行中", "未开始"

  Exam({
    required this.courseName,
    required this.timeString,
    required this.location,
    required this.type,
    required this.status,
  });
}
