
class ScheduleTable {
  int id;
  String tableName;
  int nodes; 
  String background; 
  int timeTableId; 
  String startDate; 
  int maxWeek; 
  
  
  int itemHeight;
  int itemTextSize;
  int strokeColor;
  int textColor;
  int courseTextColor;
  
  
  bool showSat;
  bool showSun;
  bool showOtherWeekCourse;
  bool showTime;
  bool showFloatingButton;

  ScheduleTable({
    this.id = 0,
    required this.tableName,
    this.nodes = 15, 
    this.background = '',
    this.timeTableId = 1,
    required this.startDate,
    this.maxWeek = 30,
    this.itemHeight = 56,
    this.itemTextSize = 12,
    this.strokeColor = 0x80ffffff,
    this.textColor = 0xff000000,
    this.courseTextColor = 0xffffffff,
    this.showSat = true,
    this.showSun = true,
    this.showOtherWeekCourse = true,
    this.showTime = false,
    this.showFloatingButton = true,
  });

  factory ScheduleTable.fromJson(Map<String, dynamic> json) {
    return ScheduleTable(
      id: json['id'] as int? ?? 0,
      tableName: json['tableName'] as String,
      nodes: json['nodes'] as int? ?? 12,
      background: json['background'] as String? ?? '',
      timeTableId: json['timeTableId'] as int? ?? 1,
      startDate: json['startDate'] as String? ?? '2024-09-01',
      maxWeek: json['maxWeek'] as int? ?? 30,
      itemHeight: json['itemHeight'] as int? ?? 56,
      itemTextSize: json['itemTextSize'] as int? ?? 12,
      strokeColor: json['strokeColor'] as int? ?? 0x80ffffff,
      textColor: json['textColor'] as int? ?? 0xff000000,
      courseTextColor: json['courseTextColor'] as int? ?? 0xffffffff,
      showSat: json['showSat'] as bool? ?? true,
      showSun: json['showSun'] as bool? ?? true,
      showOtherWeekCourse: json['showOtherWeekCourse'] as bool? ?? true,
      showTime: json['showTime'] as bool? ?? false,
      showFloatingButton: json['showFloatingButton'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'nodes': nodes,
      'background': background,
      'timeTableId': timeTableId,
      'startDate': startDate,
      'maxWeek': maxWeek,
      'itemHeight': itemHeight,
      'itemTextSize': itemTextSize,
      'strokeColor': strokeColor,
      'textColor': textColor,
      'courseTextColor': courseTextColor,
      'showSat': showSat,
      'showSun': showSun,
      'showOtherWeekCourse': showOtherWeekCourse,
      'showTime': showTime,
      'showFloatingButton': showFloatingButton,
    };
  }

  DateTime get startDateObj {
    try {
      return DateTime.parse(startDate);
    } catch (e) {
      return DateTime.now();
    }
  }
}
