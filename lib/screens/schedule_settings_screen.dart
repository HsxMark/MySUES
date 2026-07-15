import 'package:flutter/material.dart';
import '../models/schedule_table.dart';
import 'schedule_shift_screen.dart';
import 'package:mysues/l10n/l10n.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  final ScheduleTable? table; // Null for new table
  final List<String> existingNames;

  const ScheduleSettingsScreen({
    super.key,
    this.table,
    this.existingNames = const [],
  });

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _maxWeekController;
  late TextEditingController _nodesController;
  late String _startDate;
  late bool _showTime;
  late bool _showSat;
  late bool _showSun;
  late bool _showOtherWeekCourse;
  late bool _showFloatingButton;
  late bool _showHiddenCourses;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameController = TextEditingController(text: widget.table!.tableName);
      _maxWeekController = TextEditingController(
        text: widget.table!.maxWeek.toString(),
      );
      _nodesController = TextEditingController(
        text: widget.table!.nodes.toString(),
      );
      _startDate = widget.table!.startDate;
      _showTime = widget.table!.showTime;
      _showSat = widget.table!.showSat;
      _showSun = widget.table!.showSun;
      _showOtherWeekCourse = widget.table!.showOtherWeekCourse;
      _showFloatingButton = widget.table!.showFloatingButton;
      _showHiddenCourses = widget.table!.showHiddenCourses;
    } else {
      _nameController = TextEditingController();
      _maxWeekController = TextEditingController(text: '30');
      _nodesController = TextEditingController(text: '15'); // Default to 15
      _startDate = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1))
          .toIso8601String()
          .split('T')[0];
      _showTime = false;
      _showSat = true;
      _showSun = true;
      _showOtherWeekCourse = true;
      _showFloatingButton = true;
      _showHiddenCourses = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.table == null && _nameController.text.isEmpty) {
      _nameController.text = context.l10n.newSchedule;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxWeekController.dispose();
    _nodesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.scheduleSettings),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.scheduleName,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(context.l10n.semesterStartDate),
            subtitle: Text(_startDate),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxWeekController,
            decoration: InputDecoration(
              labelText: context.l10n.semesterWeeks,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nodesController,
            decoration: InputDecoration(
              labelText: context.l10n.periodsPerDay,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              context.l10n.scheduleDisplay,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(context.l10n.showCourseTimes),
            value: _showTime,
            onChanged: (v) => setState(() => _showTime = v),
          ),
          SwitchListTile(
            title: Text(context.l10n.showSaturday),
            value: _showSat,
            onChanged: (v) => setState(() => _showSat = v),
          ),
          SwitchListTile(
            title: Text(context.l10n.showSunday),
            value: _showSun,
            onChanged: (v) => setState(() => _showSun = v),
          ),
          SwitchListTile(
            title: Text(context.l10n.showCoursesFromOtherWeeks),
            value: _showOtherWeekCourse,
            onChanged: (v) => setState(() => _showOtherWeekCourse = v),
          ),
          SwitchListTile(
            title: Text(context.l10n.showFloatingJumpButton),
            subtitle: Text(context.l10n.jumpToAWeekOrDate),
            value: _showFloatingButton,
            onChanged: (v) => setState(() => _showFloatingButton = v),
          ),
          SwitchListTile(
            title: Text(context.l10n.showHiddenAttendanceExemptCourses),
            subtitle: Text(
              context.l10n.showHiddenAttendanceExemptCoursesInTheSchedule,
            ),
            value: _showHiddenCourses,
            onChanged: (v) => setState(() => _showHiddenCourses = v),
          ),
          if (widget.table != null) ...[
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                context.l10n.advancedSettings,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ListTile(
              title: Text(context.l10n.holidayScheduleAdjustments),
              subtitle: Text(context.l10n.moveClassesBetweenDates),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleShiftScreen(table: widget.table!),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_startDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = date.toIso8601String().split('T')[0];
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final maxWeek = int.tryParse(_maxWeekController.text) ?? 0;
    final nodes = int.tryParse(_nodesController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scheduleNameCannotBeEmpty)),
      );
      return;
    }
    if (maxWeek < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.aSemesterMustContainAtLeast15Weeks),
        ),
      );
      return;
    }
    if (nodes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.thereMustBeAtLeast10PeriodsPerDay)),
      );
      return;
    }
    if (widget.existingNames.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.thatScheduleNameAlreadyExistsChooseAnotherName,
          ),
        ),
      );
      return;
    }

    if (widget.table != null) {
      widget.table!.tableName = name;
      widget.table!.startDate = _startDate;
      widget.table!.maxWeek = maxWeek;
      widget.table!.nodes = nodes;
      widget.table!.showTime = _showTime;
      widget.table!.showSat = _showSat;
      widget.table!.showSun = _showSun;
      widget.table!.showOtherWeekCourse = _showOtherWeekCourse;
      widget.table!.showFloatingButton = _showFloatingButton;
      widget.table!.showHiddenCourses = _showHiddenCourses;
      Navigator.pop(context, widget.table);
    } else {
      final newTable = ScheduleTable(
        tableName: name,
        startDate: _startDate,
        maxWeek: maxWeek,
        nodes: nodes,
        timeTableId: 1, // Default time table
        showTime: _showTime,
        showSat: _showSat,
        showSun: _showSun,
        showOtherWeekCourse: _showOtherWeekCourse,
        showFloatingButton: _showFloatingButton,
        showHiddenCourses: _showHiddenCourses,
      );
      Navigator.pop(context, newTable);
    }
  }
}
