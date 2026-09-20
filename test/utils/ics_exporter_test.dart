import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/models/schedule_table.dart';
import 'package:mysues/utils/ics_exporter.dart';

void main() {
  Course buildCourse({String courseName = '算法设计'}) {
    return Course(
      id: 42,
      courseName: courseName,
      day: DateTime.sunday,
      room: '一教,101;东',
      teacher: '张老师',
      startNode: 1,
      startWeek: 1,
      endWeek: 1,
      color: '#336699',
      startTime: '02:30',
      endTime: '04:05',
    );
  }

  ScheduleTable buildTable() {
    return ScheduleTable(
      tableName: '测试课表',
      startDate: '2026-03-08',
      maxWeek: 1,
    );
  }

  test('exports stable Asia/Shanghai wall times and legacy-compatible UID', () {
    final ics = IcsExporter.generateIcsString(
      [buildCourse()],
      buildTable(),
      const [],
    );

    expect(ics, contains('BEGIN:VTIMEZONE\r\n'));
    expect(ics, contains('TZID:Asia/Shanghai\r\n'));
    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20260308T023000\r\n'));
    expect(ics, contains('DTEND;TZID=Asia/Shanghai:20260308T040500\r\n'));
    expect(
      ics,
      contains('UID:mysues_course_42_week1_1772899200000@mysues.app\r\n'),
    );
    expect(ics, contains('LOCATION:一教\\,101\\;东\r\n'));
    expect(ics.replaceAll('\r\n', ''), isNot(contains('\n')));
  });

  test('folds UTF-8 content lines without exceeding 75 octets', () {
    final longName = '${List.filled(20, '中文').join()}😀,专题;课';
    final ics = IcsExporter.generateIcsString(
      [buildCourse(courseName: longName)],
      buildTable(),
      const [],
    );

    final physicalLines = ics.split('\r\n').where((line) => line.isNotEmpty);
    expect(physicalLines.any((line) => line.startsWith(' ')), isTrue);
    for (final line in physicalLines) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
    }

    final unfolded = ics.replaceAll('\r\n ', '').replaceAll('\r\n', '\n');
    expect(
      unfolded,
      contains(
        'SUMMARY:${longName.replaceAll(',', '\\,').replaceAll(';', '\\;')}',
      ),
    );
  });
}
