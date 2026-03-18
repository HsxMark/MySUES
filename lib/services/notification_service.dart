import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/schedule_table.dart';
import '../models/time_table.dart';
import '../services/schedule_service.dart';
import '../services/exam_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _courseReminderKey = 'notification_course_reminder';
  static const String _examReminderKey = 'notification_exam_reminder';
  static const String _examReminderDaysKey = 'notification_exam_reminder_days';
  static const String _examReminderHourKey = 'notification_exam_reminder_hour';
  static const String _examReminderMinuteKey = 'notification_exam_reminder_minute';

  
  static const int _courseIdBase = 1000;
  static const int _courseIdMax = 4999;
  static const int _examIdBase = 5000;
  static const int _examIdMax = 9999;

  
  static const String _scheduledCourseIdsKey = '_scheduled_course_ids';
  static const String _scheduledExamIdsKey = '_scheduled_exam_ids';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final granted = await macos.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  

  Future<bool> getCourseReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_courseReminderKey) ?? false;
  }

  Future<bool> getExamReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_examReminderKey) ?? false;
  }

  Future<void> setCourseReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_courseReminderKey, enabled);
    if (enabled) {
      await scheduleCourseReminders();
    } else {
      await cancelCourseReminders();
    }
  }

  Future<void> setExamReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_examReminderKey, enabled);
    if (enabled) {
      await scheduleExamReminders();
    } else {
      await cancelExamReminders();
    }
  }

  
  Future<int> getExamReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_examReminderDaysKey) ?? 1;
  }

  
  Future<TimeOfDay> getExamReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_examReminderHourKey) ?? 9;
    final minute = prefs.getInt(_examReminderMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  
  Future<void> setExamReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_examReminderDaysKey, days);
    if (await getExamReminderEnabled()) {
      await scheduleExamReminders();
    }
  }

  
  Future<void> setExamReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_examReminderHourKey, time.hour);
    await prefs.setInt(_examReminderMinuteKey, time.minute);
    if (await getExamReminderEnabled()) {
      await scheduleExamReminders();
    }
  }

  
  Future<void> rescheduleAll() async {
    try {
      if (await getCourseReminderEnabled()) {
        await scheduleCourseReminders();
      }
      if (await getExamReminderEnabled()) {
        await scheduleExamReminders();
      }
    } catch (e) {
      debugPrint('NotificationService.rescheduleAll error: $e');
    }
  }

  

  Future<void> scheduleCourseReminders() async {
    await cancelCourseReminders();

    final tableId = await ScheduleDataService.getCurrentTableId();
    if (tableId == 0) return;

    final tables = await ScheduleDataService.loadScheduleTables();
    ScheduleTable? table;
    for (final t in tables) {
      if (t.id == tableId) {
        table = t;
        break;
      }
    }
    if (table == null) return;

    final courses = await ScheduleDataService.loadCourses(tableId: tableId);
    if (courses.isEmpty) return;

    final timeDetails = await ScheduleDataService.loadTimeDetails(
      timeTableId: table.timeTableId,
    );
    if (timeDetails.isEmpty) return;

    final now = DateTime.now();
    final startDate = table.startDateObj;
    final currentWeek =
        ((now.difference(startDate).inDays) / 7).floor() + 1;

    int notificationId = _courseIdBase;
    final scheduledIds = <String>[];

    
    for (int weekOffset = 0; weekOffset <= 1; weekOffset++) {
      final week = currentWeek + weekOffset;
      if (week < 1 || week > table.maxWeek) continue;

      for (final course in courses) {
        if (!course.inWeek(week)) continue;
        if (notificationId > _courseIdMax) break;

        
        TimeDetail? timeDetail;
        for (final td in timeDetails) {
          if (td.node == course.startNode) {
            timeDetail = td;
            break;
          }
        }
        if (timeDetail == null) continue;

        
        final weekStartDate = startDate.add(Duration(days: (week - 1) * 7));
        final courseDate = weekStartDate.add(Duration(days: course.day - 1));

        
        final timeParts = timeDetail.startTime.split(':');
        if (timeParts.length != 2) continue;
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour == null || minute == null) continue;

        final courseDateTime = DateTime(
          courseDate.year,
          courseDate.month,
          courseDate.day,
          hour,
          minute,
        );

        
        final notificationTime =
            courseDateTime.subtract(const Duration(minutes: 15));

        
        if (notificationTime.isBefore(now)) continue;

        final currentId = notificationId++;
        final roomInfo = course.room.isNotEmpty ? '\n教室: ${course.room}' : '';
        try {
          await _scheduleNotification(
            id: currentId,
            channelId: 'course_reminders',
            channelName: '课程提醒',
            channelDescription: '上课前15分钟提醒',
            title: '课程提醒',
            body: '${course.courseName} 将在15分钟后开始$roomInfo',
            scheduledTime: notificationTime,
          );
          scheduledIds.add(currentId.toString());
        } catch (e) {
          debugPrint('Failed to schedule course notification: $e');
        }
      }
    }

    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scheduledCourseIdsKey, scheduledIds);
  }

  Future<void> cancelCourseReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledCourseIdsKey) ?? [];
    for (final idStr in ids) {
      final id = int.tryParse(idStr);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.setStringList(_scheduledCourseIdsKey, []);
  }

  

  Future<void> scheduleExamReminders() async {
    await cancelExamReminders();

    final exams = await ExamService.loadExams();
    if (exams.isEmpty) return;

    final daysBefore = await getExamReminderDays();
    final reminderTime = await getExamReminderTime();

    final now = DateTime.now();
    int notificationId = _examIdBase;
    final scheduledIds = <String>[];

    for (final exam in exams) {
      if (exam.status == '已结束') continue;
      if (notificationId > _examIdMax) break;

      
      final examDate = _parseExamDate(exam.timeString);
      if (examDate == null) continue;

      
      final notificationTime = DateTime(
        examDate.year,
        examDate.month,
        examDate.day,
        reminderTime.hour,
        reminderTime.minute,
      ).subtract(Duration(days: daysBefore));

      
      if (notificationTime.isBefore(now)) continue;

      final currentId = notificationId++;
      final locationInfo =
          exam.location.isNotEmpty ? '\n地点: ${exam.location}' : '';
      final examTimeInfo = exam.timeString.isNotEmpty
          ? '\n时间: ${exam.timeString}'
          : '';
      final daysText = daysBefore == 1 ? '明天' : '$daysBefore天后';
      try {
        await _scheduleNotification(
          id: currentId,
          channelId: 'exam_reminders',
          channelName: '考试提醒',
          channelDescription: '考试前$daysBefore天提醒',
          title: '考试提醒',
          body:
              '${exam.courseName} $daysText考试$examTimeInfo$locationInfo',
          scheduledTime: notificationTime,
        );
        scheduledIds.add(currentId.toString());
      } catch (e) {
        debugPrint('Failed to schedule exam notification: $e');
      }
    }

    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scheduledExamIdsKey, scheduledIds);
  }

  Future<void> cancelExamReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledExamIdsKey) ?? [];
    for (final idStr in ids) {
      final id = int.tryParse(idStr);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.setStringList(_scheduledExamIdsKey, []);
  }

  

  DateTime? _parseExamDate(String timeString) {
    try {
      
      if (timeString.length >= 10) {
        final dateStr = timeString.substring(0, 10);
        return DateTime.parse(dateStr);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _scheduleNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
