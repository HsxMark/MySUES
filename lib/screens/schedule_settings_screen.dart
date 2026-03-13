import 'package:flutter/material.dart';
import '../models/schedule_table.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  final ScheduleTable? table; // Null for new table
  final List<String> existingNames;

  const ScheduleSettingsScreen({super.key, this.table, this.existingNames = const []});

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

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameController = TextEditingController(text: widget.table!.tableName);
      _maxWeekController = TextEditingController(text: widget.table!.maxWeek.toString());
      _nodesController = TextEditingController(text: widget.table!.nodes.toString());
      _startDate = widget.table!.startDate;
      _showTime = widget.table!.showTime;
      _showSat = widget.table!.showSat;
      _showSun = widget.table!.showSun;
      _showOtherWeekCourse = widget.table!.showOtherWeekCourse;
      _showFloatingButton = widget.table!.showFloatingButton;
    } else {
      _nameController = TextEditingController(text: '新课表');
      _maxWeekController = TextEditingController(text: '30');
      _nodesController = TextEditingController(text: '15'); // Default to 15
      _startDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).toIso8601String().split('T')[0];
      _showTime = false;
      _showSat = true;
      _showSun = true;
      _showOtherWeekCourse = true;
      _showFloatingButton = true;
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
        title: const Text('课表设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '课表名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('开学日期'),
            subtitle: Text(_startDate),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxWeekController,
            decoration: const InputDecoration(labelText: '学期周数', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nodesController,
            decoration: const InputDecoration(labelText: '每天节数', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('课表显示设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          SwitchListTile(
            title: const Text('显示课程时间'),
            value: _showTime,
            onChanged: (v) => setState(() => _showTime = v),
          ),
          SwitchListTile(
            title: const Text('显示周六'),
            value: _showSat,
            onChanged: (v) => setState(() => _showSat = v),
          ),
          SwitchListTile(
            title: const Text('显示周日'),
            value: _showSun,
            onChanged: (v) => setState(() => _showSun = v),
          ),
          SwitchListTile(
            title: const Text('显示非本周课程'),
            value: _showOtherWeekCourse,
            onChanged: (v) => setState(() => _showOtherWeekCourse = v),
          ),
          SwitchListTile(
            title: const Text('显示悬浮跳转按钮'),
            subtitle: const Text('快速跳转周次/日期'),
            value: _showFloatingButton,
            onChanged: (v) => setState(() => _showFloatingButton = v),
          ),
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
        const SnackBar(content: Text('课表名称不能为空')),
      );
      return;
    }
    if (maxWeek < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学期周数不能少于 15 周')),
      );
      return;
    }
    if (nodes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('每天节数不能少于 10 节')),
      );
      return;
    }
    if (widget.existingNames.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课表名称已存在，请使用其他名称')),
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
      );
       Navigator.pop(context, newTable);
    }
  }
}
