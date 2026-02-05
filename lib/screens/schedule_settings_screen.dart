import 'package:flutter/material.dart';
import '../models/schedule_table.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  final ScheduleTable table;

  const ScheduleSettingsScreen({super.key, required this.table});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _maxWeekController;
  late TextEditingController _nodesController;
  late String _startDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table.tableName);
    _maxWeekController = TextEditingController(text: widget.table.maxWeek.toString());
    _nodesController = TextEditingController(text: widget.table.nodes.toString());
    _startDate = widget.table.startDate;
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
    final maxWeek = int.tryParse(_maxWeekController.text) ?? 20;
    final nodes = int.tryParse(_nodesController.text) ?? 12;

    widget.table.tableName = _nameController.text;
    widget.table.startDate = _startDate;
    widget.table.maxWeek = maxWeek;
    widget.table.nodes = nodes;

    Navigator.pop(context, widget.table);
  }
}
