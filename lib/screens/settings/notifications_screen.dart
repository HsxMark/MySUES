import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'package:mysues/l10n/legacy_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _courseReminder = false;
  bool _examReminder = false;
  int _examDaysBefore = 1;
  TimeOfDay _examTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;

  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final course = await _notificationService.getCourseReminderEnabled();
    final exam = await _notificationService.getExamReminderEnabled();
    final days = await _notificationService.getExamReminderDays();
    final time = await _notificationService.getExamReminderTime();
    if (mounted) {
      setState(() {
        _courseReminder = course;
        _examReminder = exam;
        _examDaysBefore = days;
        _examTime = time;
        _loading = false;
      });
    }
  }

  Future<void> _toggleCourseReminder(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: LText('需要通知权限才能设置课程提醒')));
        }
        return;
      }
    }

    setState(() => _courseReminder = value);
    await _notificationService.setCourseReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LText(value ? '已开启课程提醒' : '已关闭课程提醒'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleExamReminder(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: LText('需要通知权限才能设置考试提醒')));
        }
        return;
      }
    }

    setState(() => _examReminder = value);
    await _notificationService.setExamReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LText(value ? '已开启考试提醒' : '已关闭考试提醒'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _selectExamDays() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const LText('提前几天提醒'),
        children: List.generate(7, (index) {
          final days = index + 1;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, days),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (days == _examDaysBefore)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 12),
                  LText('提前 $days 天', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }),
      ),
    );

    if (result != null && result != _examDaysBefore) {
      setState(() => _examDaysBefore = result);
      await _notificationService.setExamReminderDays(result);
    }
  }

  Future<void> _selectExamTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _examTime,
      helpText: '选择提醒时间',
    );

    if (result != null && result != _examTime) {
      setState(() => _examTime = result);
      await _notificationService.setExamReminderTime(result);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LText('通知')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const LText('课程提醒'),
                  subtitle: const LText('上课前15分钟提醒'),
                  secondary: const Icon(Icons.school_outlined),
                  value: _courseReminder,
                  onChanged: _toggleCourseReminder,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const LText('考试提醒'),
                  subtitle: LText(
                    _examReminder
                        ? '考试前 $_examDaysBefore 天 ${_formatTime(_examTime)} 提醒'
                        : '开启后可自定义提醒时间',
                  ),
                  secondary: const Icon(Icons.event_note_outlined),
                  value: _examReminder,
                  onChanged: _toggleExamReminder,
                ),
                if (_examReminder) ...[
                  ListTile(
                    title: const LText('提前天数'),
                    subtitle: LText('考试前 $_examDaysBefore 天'),
                    leading: const SizedBox(width: 24),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectExamDays,
                  ),
                  ListTile(
                    title: const LText('提醒时间'),
                    subtitle: LText(_formatTime(_examTime)),
                    leading: const SizedBox(width: 24),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectExamTime,
                  ),
                ],
              ],
            ),
    );
  }
}
