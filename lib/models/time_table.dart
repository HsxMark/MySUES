
class TimeTable {
  int id;
  String name;
  
  TimeTable({
    this.id = 0,
    required this.name,
  });

  factory TimeTable.fromJson(Map<String, dynamic> json) {
    return TimeTable(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}


class TimeDetail {
  int node; 
  String startTime; 
  String endTime; 
  int timeTableId;

  TimeDetail({
    required this.node,
    required this.startTime,
    required this.endTime,
    required this.timeTableId,
  });

  factory TimeDetail.fromJson(Map<String, dynamic> json) {
    return TimeDetail(
      node: json['node'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      timeTableId: json['timeTableId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': node,
      'startTime': startTime,
      'endTime': endTime,
      'timeTableId': timeTableId,
    };
  }
}
