import 'package:flutter/material.dart';


class Course {
  int id;
  String courseName;
  int day; 
  String room;
  String teacher;
  int startNode; 
  int step; 
  int startWeek; 
  int endWeek; 
  int type; 
  String color; 
  int tableId; 
  String? startTime; 
  String? endTime; 

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
    this.startTime,
    this.endTime,
  });

  
  String get nodeString => '第$startNode - ${startNode + step - 1}节';

  
  bool inWeek(int week) {
    if (week < startWeek || week > endWeek) {
      return false;
    }
    switch (type) {
      case 0: 
        return true;
      case 1: 
        return week % 2 == 1;
      case 2: 
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
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
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
      'startTime': startTime,
      'endTime': endTime,
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
