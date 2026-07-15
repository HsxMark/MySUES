import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'package:mysues/l10n/l10n.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.notificationPermissionIsRequiredForClassReminders,
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _courseReminder = value);
    await _notificationService.setCourseReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? context.l10n.classRemindersEnabled
                : context.l10n.classRemindersDisabled,
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.notificationPermissionIsRequiredForExamReminders,
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _examReminder = value);
    await _notificationService.setExamReminderEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? context.l10n.examRemindersEnabled
                : context.l10n.examRemindersDisabled,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _selectExamDays() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.daysBefore),
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
                  Text(
                    context.l10n.daysInAdvanceValue(days),
                    style: const TextStyle(fontSize: 16),
                  ),
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
      helpText: context.l10n.chooseReminderTime,
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
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(context.l10n.courseReminder),
                  subtitle: Text(context.l10n.remindMe15MinutesBeforeClass),
                  secondary: const Icon(Icons.school_outlined),
                  value: _courseReminder,
                  onChanged: _toggleCourseReminder,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(context.l10n.examReminder),
                  subtitle: Text(
                    _examReminder
                        ? context.l10n.examReminderAt(
                            _examDaysBefore,
                            _formatTime(_examTime),
                          )
                        : context.l10n.enableToChooseACustomReminderTime,
                  ),
                  secondary: const Icon(Icons.event_note_outlined),
                  value: _examReminder,
                  onChanged: _toggleExamReminder,
                ),
                if (_examReminder) ...[
                  ListTile(
                    title: Text(context.l10n.daysInAdvance),
                    subtitle: Text(
                      context.l10n.examDaysBefore(_examDaysBefore),
                    ),
                    leading: const SizedBox(width: 24),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectExamDays,
                  ),
                  ListTile(
                    title: Text(context.l10n.reminderTime),
                    subtitle: Text(_formatTime(_examTime)),
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
