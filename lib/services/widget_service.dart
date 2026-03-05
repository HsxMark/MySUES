import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/schedule_service.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/models/schedule_table.dart';

class WidgetService {
  static const String appGroupId = 'group.com.hsxmark.mysues';
  static const String iOSWidgetName = 'ScheduleWidget';
  static const String androidWidgetName = 'ScheduleWidgetProvider';

  static Future<void> updateWidget() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      final currentTableId = await ScheduleDataService.getCurrentTableId();
      final allTables = await ScheduleDataService.loadScheduleTables();
      
      ScheduleTable? currentTable;
      try {
        currentTable = allTables.firstWhere((t) => t.id == currentTableId);
      } catch (e) {
        if (allTables.isNotEmpty) currentTable = allTables.first;
      }

      if (currentTable == null) {
        await HomeWidget.saveWidgetData('title', '未设置课表');
        await HomeWidget.saveWidgetData('week', '');
        for (int i = 1; i <= 6; i++) {
          await HomeWidget.saveWidgetData('course_${i}_name', '');
        }
        await HomeWidget.updateWidget(
          androidName: androidWidgetName,
          iOSName: iOSWidgetName,
        );
        return;
      }

      final now = DateTime.now();
      // Calculate current week
      final startTermDate = currentTable.startDate != null 
          ? DateTime.parse(currentTable.startDate!)
          : null;
      
      int currentWeek = 1;
      if (startTermDate != null) {
        final days = now.difference(startTermDate).inDays;
        currentWeek = (days / 7).floor() + 1;
      }
      
      int weekday = now.weekday; // 1..7 (Mon..Sun)

      final title = '${currentTable.tableName} | ${now.month}.${now.day} ${_getWeekdayString(weekday)}';
      final weekStr = '第 $currentWeek 周';

      await HomeWidget.saveWidgetData('title', title);
      await HomeWidget.saveWidgetData('week', weekStr);

      final allCourses = await ScheduleDataService.loadCourses(tableId: currentTable.id);
      final todayCourses = allCourses.where((c) => c.day == weekday && c.inWeek(currentWeek)).toList();
      todayCourses.sort((a, b) => a.startNode.compareTo(b.startNode));

      final timeDetails = await ScheduleDataService.loadTimeDetails(timeTableId: currentTable.timeTableId);

      for (int i = 1; i <= 6; i++) {
        if (i <= todayCourses.length) {
          final course = todayCourses[i - 1];
          await HomeWidget.saveWidgetData('course_${i}_name', course.courseName);
          
          String startTime = course.startTime ?? '';
          String endTime = course.endTime ?? '';
          if (startTime.isEmpty && timeDetails.isNotEmpty) {
             final startDetail = timeDetails.cast<dynamic>().firstWhere((d) => d.node == course.startNode, orElse: () => null);
             if (startDetail != null) {
                 startTime = startDetail.startTime;
             }
          }
          if (endTime.isEmpty && timeDetails.isNotEmpty) {
             final endNode = course.startNode + course.step - 1;
             final endDetail = timeDetails.cast<dynamic>().firstWhere((d) => d.node == endNode, orElse: () => null);
             if (endDetail != null) {
                 endTime = endDetail.endTime;
             }
          }

          await HomeWidget.saveWidgetData('course_${i}_time', startTime);
          await HomeWidget.saveWidgetData('course_${i}_endtime', endTime);
          await HomeWidget.saveWidgetData('course_${i}_loc', '${course.room} ${course.teacher}'.trim());
        } else {
          await HomeWidget.saveWidgetData('course_${i}_name', '');
          await HomeWidget.saveWidgetData('course_${i}_time', '');
          await HomeWidget.saveWidgetData('course_${i}_endtime', '');
          await HomeWidget.saveWidgetData('course_${i}_loc', '');
        }
      }

      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }

  static String _getWeekdayString(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    if (weekday >= 1 && weekday <= 7) return weekdays[weekday - 1];
    return '';
  }
}
