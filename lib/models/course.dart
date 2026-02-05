import 'package:flutter/material.dart';

/// 课程模型，对应 WakeupSchedule_Kotlin 中的 CourseBean
class Course {
  int id;
  String courseName;
  int day; // 星期几 1-7
  String room;
  String teacher;
  int startNode; // 开始节次
  int step; // 持续节数
  int startWeek; // 开始周
  int endWeek; // 结束周
  int type; // 0: 每周, 1: 单周, 2: 双周
  String color; // Hex color string, e.g. "#FF0000"
  int tableId; // 所属课表ID

  Course({
    this.id = 0,
    required this.courseName,
    required this.day,
    this.room = '',
    this.teacher = '',
    required this.startNode,
    this.step = 1,
    required this.startWeek,
    required this.endWeek,
    this.type = 0,
    required this.color,
    this.tableId = 0,
  });

  /// 获取节次描述字符串
  String get nodeString => '第$startNode - ${startNode + step - 1}节';

  /// 判断指定周次是否有课
  bool inWeek(int week) {
    if (week < startWeek || week > endWeek) {
      return false;
    }
    switch (type) {
      case 0: // 每周
        return true;
      case 1: // 单周
        return week % 2 == 1;
      case 2: // 双周
        return week % 2 == 0;
      default:
        return false;
    }
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int? ?? 0,
      courseName: json['courseName'] as String,
      day: json['day'] as int,
      room: json['room'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      startNode: json['startNode'] as int,
      step: json['step'] as int,
      startWeek: json['startWeek'] as int,
      endWeek: json['endWeek'] as int,
      type: json['type'] as int,
      color: json['color'] as String,
      tableId: json['tableId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'day': day,
      'room': room,
      'teacher': teacher,
      'startNode': startNode,
      'step': step,
      'startWeek': startWeek,
      'endWeek': endWeek,
      'type': type,
      'color': color,
      'tableId': tableId,
    };
  }

  Color get colorObj {
    try {
      if (color.isEmpty) return Colors.blue;
      var hexColor = color.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return Colors.blue;
    }
  }
}
