import 'package:flutter/material.dart';
import '../models/schedule_table.dart';
import '../models/course.dart';
import '../services/schedule_service.dart';
import 'package:mysues/l10n/l10n.dart';

class ScheduleShiftScreen extends StatefulWidget {
  final ScheduleTable table;

  const ScheduleShiftScreen({super.key, required this.table});

  @override
  State<ScheduleShiftScreen> createState() => _ScheduleShiftScreenState();
}

class _ScheduleShiftScreenState extends State<ScheduleShiftScreen> {
  DateTime? _dateA;
  DateTime? _dateB;
  bool _isProcessing = false;

  int _calculateWeek(DateTime date) {
    final startDate =
        DateTime.tryParse(widget.table.startDate) ?? DateTime.now();
    final startMonday = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = targetDate.difference(startMonday).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  Future<void> _pickDate(bool isA) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isA ? _dateA : _dateB) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isA) {
          _dateA = date;
        } else {
          _dateB = date;
        }
      });
    }
  }

  Future<void> _processShift() async {
    if (_dateA == null || _dateB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseBothDatesFirst)),
      );
      return;
    }

    // Clear time portion for safe calculation
    final dateA = DateTime(_dateA!.year, _dateA!.month, _dateA!.day);
    final dateB = DateTime(_dateB!.year, _dateB!.month, _dateB!.day);

    if (dateA.isAtSameMomentAs(dateB)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.theDatesMustBeDifferent)),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final weekA = _calculateWeek(dateA);
      final dayA = dateA.weekday;

      final weekB = _calculateWeek(dateB);
      final dayB = dateB.weekday;

      final allCourses = await ScheduleDataService.loadCourses(
        tableId: widget.table.id,
      );
      final List<Course> finalCourses = [];
      final List<Course> coursesToAdd = [];

      int maxId = 0;
      for (var c in allCourses) {
        if (c.id > maxId) maxId = c.id;
      }

      int nextId() {
        maxId++;
        return maxId;
      }

      for (var c in allCourses) {
        bool matchesA = (c.day == dayA && c.inWeek(weekA));
        bool matchesB = (c.day == dayB && c.inWeek(weekB));

        if (!matchesA && !matchesB) {
          finalCourses.add(c);
          continue;
        }

        // Determine specific weeks to exclude for this course
        List<int> excludeWeeks = [];
        if (matchesA) excludeWeeks.add(weekA);
        if (matchesB) excludeWeeks.add(weekB);
        excludeWeeks.sort();

        // Break the course into valid segments avoiding excluded weeks
        int currentStart = c.startWeek;
        for (int ex in excludeWeeks) {
          if (currentStart <= ex - 1) {
            finalCourses.add(
              _copyCourse(
                c,
                newId: nextId(),
                newStartWeek: currentStart,
                newEndWeek: ex - 1,
              ),
            );
          }
          currentStart = ex + 1;
        }
        if (currentStart <= c.endWeek) {
          finalCourses.add(
            _copyCourse(
              c,
              newId: nextId(),
              newStartWeek: currentStart,
              newEndWeek: c.endWeek,
            ),
          );
        }

        // Shift A to B
        if (matchesA) {
          final shifted = _copyCourse(
            c,
            newId: nextId(),
            newStartWeek: weekB,
            newEndWeek: weekB,
            newType: 0,
            newDay: dayB,
          );
          coursesToAdd.add(shifted);
        }
      }

      finalCourses.addAll(coursesToAdd);

      // Now we need to save everything.
      // But wait! ScheduleDataService.saveCourses saves ALL courses, not just current table.
      // So load ALL courses globally, replace the ones for this table.
      final globalCourses = await ScheduleDataService.loadCourses();
      globalCourses.removeWhere((c) => c.tableId == widget.table.id);
      globalCourses.addAll(finalCourses);

      await ScheduleDataService.saveCourses(globalCourses);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scheduleAdjustmentCompleted)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.processingFailedWithError('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Course _copyCourse(
    Course c, {
    required int newId,
    int? newStartWeek,
    int? newEndWeek,
    int? newType,
    int? newDay,
  }) {
    return Course(
      id: newId,
      courseName: c.courseName,
      day: newDay ?? c.day,
      room: c.room,
      teacher: c.teacher,
      startNode: c.startNode,
      step: c.step,
      startWeek: newStartWeek ?? c.startWeek,
      endWeek: newEndWeek ?? c.endWeek,
      type: newType ?? c.type,
      color: c.color,
      tableId: c.tableId,
      startTime: c.startTime,
      endTime: c.endTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scheduleAdjustment)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            context.l10n.holidayAdjustmentInstructionsThisMovesClassesFromDateA,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: Text(context.l10n.chooseSourceDate),
            subtitle: Text(
              _dateA == null
                  ? context.l10n.notSelected
                  : '${_dateA!.year}-${_dateA!.month.toString().padLeft(2, '0')}-${_dateA!.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 16),
          const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
          const SizedBox(height: 16),
          ListTile(
            title: Text(context.l10n.chooseTargetDate),
            subtitle: Text(
              _dateB == null
                  ? context.l10n.notSelected
                  : '${_dateB!.year}-${_dateB!.month.toString().padLeft(2, '0')}-${_dateB!.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isProcessing ? null : _processShift,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator()
                : Text(
                    context.l10n.confirmAdjustment,
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
