import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/services/schedule_service.dart';
import 'package:mysues/models/schedule_table.dart';
import 'package:mysues/models/time_table.dart';
import 'package:mysues/utils/building_time_override.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/services/locale_service.dart';

class WidgetService {
  static const String appGroupId = 'group.com.hsxmark.mysues';
  static const String iOSWidgetName = 'ScheduleWidget';
  static const String androidWidgetName = 'ScheduleWidgetProvider';
  static const String scheduleDaysKey = 'schedule_days_v1';
  static const int cachedDayCount = 14;

  static Future<void> updateWidget() async {
    try {
      await LocaleService().loadSettings();
      final locale = LocaleService().effectiveLocale;
      final l10n = await AppLocalizations.delegate.load(locale);
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData('effective_locale', locale.languageCode);

      final currentTableId = await ScheduleDataService.getCurrentTableId();
      final allTables = await ScheduleDataService.loadScheduleTables();

      ScheduleTable? currentTable;
      try {
        currentTable = allTables.firstWhere((t) => t.id == currentTableId);
      } catch (e) {
        if (allTables.isNotEmpty) currentTable = allTables.first;
      }

      if (currentTable == null) {
        await _saveScheduleDays({
          'version': 1,
          'generatedAt': _formatDate(DateTime.now()),
          'validThrough': '',
          'days': <Map<String, dynamic>>[],
        });
        await _writeLegacyEmpty(title: l10n.scheduleNotConfigured);
        await HomeWidget.updateWidget(
          androidName: androidWidgetName,
          iOSName: iOSWidgetName,
        );
        return;
      }

      final now = DateTime.now();
      final today = _dateOnly(now);
      final allCourses = await ScheduleDataService.loadCourses(
        tableId: currentTable.id,
      );
      final timeDetails = await ScheduleDataService.loadTimeDetails(
        timeTableId: currentTable.timeTableId,
      );
      final days = <Map<String, dynamic>>[];

      for (int offset = 0; offset < cachedDayCount; offset++) {
        final date = today.add(Duration(days: offset));
        days.add(
          _buildDayEntry(
            date: date,
            table: currentTable,
            allCourses: allCourses,
            timeDetails: timeDetails,
            l10n: l10n,
          ),
        );
      }

      await _saveScheduleDays({
        'version': 1,
        'generatedAt': _formatDate(today),
        'validThrough': _formatDate(
          today.add(const Duration(days: cachedDayCount - 1)),
        ),
        'days': days,
      });

      final todayEntry = days.first;
      final upcomingToday = _filterUpcomingCourses(
        (todayEntry['courses'] as List).cast<Map<String, dynamic>>(),
        now,
      );
      await _writeLegacyDay(todayEntry, upcomingToday);

      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }

  static Map<String, dynamic> _buildDayEntry({
    required DateTime date,
    required ScheduleTable table,
    required List<Course> allCourses,
    required List<TimeDetail> timeDetails,
    required AppLocalizations l10n,
  }) {
    final week = _calculateWeekForDate(date, table.startDateObj);
    final courses =
        allCourses
            .where(
              (course) =>
                  course.day == date.weekday &&
                  course.inWeek(week) &&
                  (!course.isHidden || table.showHiddenCourses),
            )
            .toList()
          ..sort((a, b) => a.startNode.compareTo(b.startNode));

    return {
      'date': _formatDate(date),
      'title': l10n.weekdayShort(
        date.month,
        date.day,
        _getWeekdayString(date.weekday, l10n),
      ),
      'week': l10n.weekNumber(week),
      'courses': courses
          .map((course) => _buildCourseEntry(course, timeDetails))
          .toList(),
    };
  }

  static Map<String, dynamic> _buildCourseEntry(
    Course course,
    List<TimeDetail> timeDetails,
  ) {
    final startTime = _resolveStartTime(course, timeDetails);
    final endTime = _resolveEndTime(course, timeDetails);

    return {
      'name': course.courseName,
      'time': startTime,
      'endTime': endTime,
      'loc': '${course.room} ${course.teacher}'.trim(),
      'color': course.color,
    };
  }

  static String _resolveStartTime(Course course, List<TimeDetail> timeDetails) {
    var startTime = course.startTime ?? '';
    if (startTime.isNotEmpty) return startTime;

    startTime =
        BuildingTimeOverride.getOverrideStartTime(
          course.room,
          course.startNode,
        ) ??
        '';
    if (startTime.isNotEmpty) return startTime;

    return _findTimeDetail(timeDetails, course.startNode)?.startTime ?? '';
  }

  static String _resolveEndTime(Course course, List<TimeDetail> timeDetails) {
    var endTime = course.endTime ?? '';
    if (endTime.isNotEmpty) return endTime;

    final endNode = course.startNode + course.step - 1;
    endTime =
        BuildingTimeOverride.getOverrideEndTime(course.room, endNode) ?? '';
    if (endTime.isNotEmpty) return endTime;

    return _findTimeDetail(timeDetails, endNode)?.endTime ?? '';
  }

  static TimeDetail? _findTimeDetail(List<TimeDetail> timeDetails, int node) {
    for (final detail in timeDetails) {
      if (detail.node == node) return detail;
    }
    return null;
  }

  static List<Map<String, dynamic>> _filterUpcomingCourses(
    List<Map<String, dynamic>> courses,
    DateTime now,
  ) {
    final currentMinutes = now.hour * 60 + now.minute;
    return courses.where((course) {
      final endTime = course['endTime'] as String? ?? '';
      final endMinutes = _parseMinutes(endTime);
      return endMinutes == null || endMinutes > currentMinutes;
    }).toList();
  }

  static int? _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  static int _calculateWeekForDate(DateTime date, DateTime startDate) {
    final normalizedDate = _dateOnly(date);
    final startMonday = _dateOnly(
      startDate,
    ).subtract(Duration(days: startDate.weekday - 1));
    return (normalizedDate.difference(startMonday).inDays / 7).floor() + 1;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _saveScheduleDays(Map<String, dynamic> data) async {
    await HomeWidget.saveWidgetData(scheduleDaysKey, jsonEncode(data));
  }

  static Future<void> _writeLegacyEmpty({required String title}) async {
    await HomeWidget.saveWidgetData('title', title);
    await HomeWidget.saveWidgetData('week', '');
    await HomeWidget.saveWidgetData('updateDate', _formatDate(DateTime.now()));
    for (int i = 1; i <= 8; i++) {
      await HomeWidget.saveWidgetData('course_${i}_name', '');
      await HomeWidget.saveWidgetData('course_${i}_time', '');
      await HomeWidget.saveWidgetData('course_${i}_endtime', '');
      await HomeWidget.saveWidgetData('course_${i}_loc', '');
      await HomeWidget.saveWidgetData('course_${i}_color', '');
    }
  }

  static Future<void> _writeLegacyDay(
    Map<String, dynamic> day,
    List<Map<String, dynamic>> courses,
  ) async {
    await HomeWidget.saveWidgetData('title', day['title'] as String? ?? '今日无课');
    await HomeWidget.saveWidgetData('week', day['week'] as String? ?? '');
    await HomeWidget.saveWidgetData(
      'updateDate',
      day['date'] as String? ?? _formatDate(DateTime.now()),
    );

    for (int i = 1; i <= 8; i++) {
      if (i <= courses.length) {
        final course = courses[i - 1];
        await HomeWidget.saveWidgetData(
          'course_${i}_name',
          course['name'] as String? ?? '',
        );
        await HomeWidget.saveWidgetData(
          'course_${i}_time',
          course['time'] as String? ?? '',
        );
        await HomeWidget.saveWidgetData(
          'course_${i}_endtime',
          course['endTime'] as String? ?? '',
        );
        await HomeWidget.saveWidgetData(
          'course_${i}_loc',
          course['loc'] as String? ?? '',
        );
        await HomeWidget.saveWidgetData(
          'course_${i}_color',
          course['color'] as String? ?? '',
        );
      } else {
        await HomeWidget.saveWidgetData('course_${i}_name', '');
        await HomeWidget.saveWidgetData('course_${i}_time', '');
        await HomeWidget.saveWidgetData('course_${i}_endtime', '');
        await HomeWidget.saveWidgetData('course_${i}_loc', '');
        await HomeWidget.saveWidgetData('course_${i}_color', '');
      }
    }
  }

  static String _getWeekdayString(int weekday, AppLocalizations l10n) {
    final weekdays = [
      l10n.mondayShort,
      l10n.tuesdayShort,
      l10n.wednesdayShort,
      l10n.thursdayShort,
      l10n.fridayShort,
      l10n.saturdayShort,
      l10n.sundayShort,
    ];
    if (weekday >= 1 && weekday <= 7) return weekdays[weekday - 1];
    return '';
  }
}
