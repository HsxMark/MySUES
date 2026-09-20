import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart';
import '../utils/building_time_override.dart';

class IcsExporter {
  /// 导出并分享一份或多份课程的 ICS 日历文件
  static Future<void> exportCourses(
    BuildContext context,
    List<Course> courses, 
    ScheduleTable currentTable, 
    List<TimeDetail> timeDetails, 
    {String fileName = 'mysues_schedule.ics'}
  ) async {
    final icsString = generateIcsString(courses, currentTable, timeDetails);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(icsString);
    
    // Provide sharePositionOrigin for iPad support
    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    await Share.shareXFiles(
      [XFile(file.path)],
      sharePositionOrigin: rect,
    );
  }

  /// 针对一组课程生成完整的 ICS 文件字符串
  static String generateIcsString(
    List<Course> courses, 
    ScheduleTable currentTable, 
    List<TimeDetail> timeDetails
  ) {
    final buffer = StringBuffer();
    void writeLine(String line) => _writeContentLine(buffer, line);

    writeLine('BEGIN:VCALENDAR');
    writeLine('VERSION:2.0');
    writeLine('PRODID:-//MySUES//Calendar Planner//ZH_CN');
    writeLine('CALSCALE:GREGORIAN');
    writeLine('METHOD:PUBLISH');
    writeLine('X-WR-CALNAME:MySUES 课程表');
    writeLine('X-WR-TIMEZONE:Asia/Shanghai');

    writeLine('BEGIN:VTIMEZONE');
    writeLine('TZID:Asia/Shanghai');
    writeLine('X-LIC-LOCATION:Asia/Shanghai');
    writeLine('BEGIN:STANDARD');
    writeLine('DTSTART:19700101T000000');
    writeLine('TZOFFSETFROM:+0800');
    writeLine('TZOFFSETTO:+0800');
    writeLine('TZNAME:CST');
    writeLine('END:STANDARD');
    writeLine('END:VTIMEZONE');
    
    final DateFormat icsDateFormat = DateFormat("yyyyMMdd'T'HHmmss");
    final String nowUtcStr = icsDateFormat.format(DateTime.now().toUtc());
    final String nowStr = '${nowUtcStr}Z';
    
    // Normalize date-only arithmetic to UTC so device DST rules cannot shift it.
    final startDate = currentTable.startDateObj;
    final normalizedStartDate = DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final startMonday = normalizedStartDate.subtract(
      Duration(days: normalizedStartDate.weekday - 1),
    );

    for (var course in courses) {
      if (course.isHidden) continue;

      for (int week = 1; week <= currentTable.maxWeek; week++) {
        if (!course.inWeek(week)) continue;
        
        // 计算目标日期：开学周一 + (第几周 - 1)*7天 + 星期几-1天
        final daysOffset = (week - 1) * 7 + (course.day - 1);
        final targetDate = startMonday.add(Duration(days: daysOffset));
        
        // 查找首尾上课时间点
        String startHm = _getCourseStartTime(course, timeDetails);
        String endHm = _getCourseEndTime(course, timeDetails);
        
        final startParts = startHm.split(':');
        final courseStart = DateTime.utc(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );

        final endParts = endHm.split(':');
        final courseEnd = DateTime.utc(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        writeLine('BEGIN:VEVENT');
        writeLine('DTSTAMP:$nowStr');
        writeLine(
          'DTSTART;TZID=Asia/Shanghai:${icsDateFormat.format(courseStart)}',
        );
        writeLine(
          'DTEND;TZID=Asia/Shanghai:${icsDateFormat.format(courseEnd)}',
        );
        writeLine('SUMMARY:${_escapeText(course.courseName)}');
        if (course.room.isNotEmpty) {
          writeLine('LOCATION:${_escapeText(course.room)}');
        }
        
        final description =
            '教师: ${course.teacher.isNotEmpty ? course.teacher : '未知'}\n'
            '节次: 第${course.startNode} - '
            '${course.startNode + course.step - 1}节';
        writeLine('DESCRIPTION:${_escapeText(description)}');
        final uidDateMillis = _legacyShanghaiEpochMillis(targetDate);
        writeLine(
          'UID:mysues_course_${course.id}_week${week}_'
          '$uidDateMillis@mysues.app',
        );
        writeLine('END:VEVENT');
      }
    }

    writeLine('END:VCALENDAR');
    return buffer.toString();
  }

  /// Reproduces the legacy UID date component for the app's UTC+08:00 users
  /// without depending on the device timezone.
  static int _legacyShanghaiEpochMillis(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day)
        .subtract(const Duration(hours: 8))
        .millisecondsSinceEpoch;
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('\r\n', '\\n')
        .replaceAll('\r', '\\n')
        .replaceAll('\n', '\\n')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,');
  }

  static void _writeContentLine(StringBuffer buffer, String line) {
    const maxOctets = 75;
    var octetsOnLine = 0;

    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final characterOctets = utf8.encode(character).length;

      if (octetsOnLine + characterOctets > maxOctets) {
        buffer.write('\r\n ');
        octetsOnLine = 1;
      }

      buffer.write(character);
      octetsOnLine += characterOctets;
    }

    buffer.write('\r\n');
  }

  static String _getCourseStartTime(Course course, List<TimeDetail> timeDetails) {
    if (course.startTime != null && course.startTime!.isNotEmpty) {
      return course.startTime!;
    }
    final override = BuildingTimeOverride.getOverrideStartTime(
      course.room,
      course.startNode,
    );
    if (override != null) return override;

    try {
      final detail = timeDetails.firstWhere((t) => t.node == course.startNode);
      return detail.startTime;
    } catch (e) {
      return "08:00";
    }
  }

  static String _getCourseEndTime(Course course, List<TimeDetail> timeDetails) {
    if (course.endTime != null && course.endTime!.isNotEmpty) {
      return course.endTime!;
    }
    final endNode = course.startNode + course.step - 1;
    final override = BuildingTimeOverride.getOverrideEndTime(
      course.room,
      endNode,
    );
    if (override != null) return override;

    try {
      final detail = timeDetails.firstWhere((t) => t.node == endNode);
      return detail.endTime; // return corresponding node's end time
    } catch (e) {
      return "09:00";
    }
  }
}
