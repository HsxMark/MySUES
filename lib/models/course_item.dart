import 'package:flutter/material.dart';

/// 课程信息模型
class CourseItem {
  /// 课程名称
  final String title;

  /// 课程类型（如：必修、选修等）
  final String type;

  /// 上课地点
  final String location;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 课程持续的节数
  final int count;

  /// 课程卡片颜色
  final Color color;

  /// 教学老师
  final String teacher;

  /// 上课周次列表（如：[1,2,3,4,5]表示1-5周）
  final List<int> weekNumbers;

  CourseItem({
    required this.title,
    required this.type,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.count,
    required this.color,
    this.teacher = '',
    this.weekNumbers = const [],
  });

  /// 从JSON创建课程对象
  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      title: json['title'] as String,
      type: json['type'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      count: json['count'] as int,
      color: Color(json['color'] as int),
      teacher: json['teacher'] as String? ?? '',
      weekNumbers:
          (json['weekNumbers'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'count': count,
      'color': color.value,
      'teacher': teacher,
      'weekNumbers': weekNumbers,
    };
  }

  /// 复制课程对象，允许修改某些字段
  CourseItem copyWith({
    String? title,
    String? type,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? count,
    Color? color,
    String? teacher,
    List<int>? weekNumbers,
  }) {
    return CourseItem(
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      count: count ?? this.count,
      color: color ?? this.color,
      teacher: teacher ?? this.teacher,
      weekNumbers: weekNumbers ?? this.weekNumbers,
    );
  }
}
