import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';

class AddExamScreen extends StatefulWidget {
  final Exam? existingExam;
  const AddExamScreen({super.key, this.existingExam});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _courseName = '';
  // String _timeString = ''; // Dynamically generated
  String _location = '';
  late TextEditingController _typeController;
  
  // New Controllers for separated time input
  final TextEditingController _startDateTimeController = TextEditingController();
  final TextEditingController _endDateTimeController = TextEditingController();
  
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  final String _status = '未结束'; 

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: '期末');

    if (widget.existingExam != null) {
      _courseName = widget.existingExam!.courseName;
      _location = widget.existingExam!.location;
      _typeController.text = widget.existingExam!.type;
      
      _parseExistingTime(widget.existingExam!.timeString);
    }
  }

  void _parseExistingTime(String timeString) {
    // Try to parse "YYYY-MM-DD HH:MM~HH:MM" or "YYYY-MM-DD HH:MM"
    try {
      final parts = timeString.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts[1];
        
        if (timePart.contains('~')) {
           final times = timePart.split('~');
           if (times.length == 2) {
             final startStr = "$datePart ${times[0]}";
             final endStr = "$datePart ${times[1]}";
             
             _startDateTime = DateTime.tryParse("$startStr:00");
             _endDateTime = DateTime.tryParse("$endStr:00");
           }
        } else if (timePart.contains('-')) {
             final times = timePart.split('-');
             if (times.length == 2) {
             final startStr = "$datePart ${times[0]}";
             final endStr = "$datePart ${times[1]}";
             
             _startDateTime = DateTime.tryParse("$startStr:00");
             _endDateTime = DateTime.tryParse("$endStr:00");
           }
        } else {
          // Single point in time
          _startDateTime = DateTime.tryParse("$timeString:00");
          // If no end time, assume 2 hours later default? or same?
          if (_startDateTime != null) {
             _endDateTime = _startDateTime!.add(const Duration(hours: 2));
           }
        }
      }
      
      if (_startDateTime != null) {
        _startDateTimeController.text = _formatDateTime(_startDateTime!);
      }
      if (_endDateTime != null) {
        _endDateTimeController.text = _formatDateTime(_endDateTime!);
      }
      
    } catch (e) {
      debugPrint("Error parsing time: $e");
    }
  }
  
  String _formatDateTime(DateTime dt) {
     return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }

  @override
  void dispose() {
    _typeController.dispose();
    _startDateTimeController.dispose();
    _endDateTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDateTime() async {
    final dt = await _showDateTimePicker(initial: _startDateTime);
    if (dt != null) {
      setState(() {
        _startDateTime = dt;
        _startDateTimeController.text = _formatDateTime(dt);
        
        // Auto-set end time to start + 2h if not set or invalid
        if (_endDateTime == null || _endDateTime!.isBefore(dt)) {
            _endDateTime = dt.add(const Duration(hours: 2));
            _endDateTimeController.text = _formatDateTime(_endDateTime!);
        }
      });
    }
  }
  
  Future<void> _pickEndDateTime() async {
    // Prevent picking a date before start date
    final dt = await _showDateTimePicker(
      initial: _endDateTime ?? _startDateTime?.add(const Duration(hours: 2)),
      minDate: _startDateTime,
    );
    if (dt != null) {
      setState(() {
        _endDateTime = dt;
        _endDateTimeController.text = _formatDateTime(dt);
      });
    }
  }

  Future<DateTime?> _showDateTimePicker({DateTime? initial, DateTime? minDate}) async {
    final now = DateTime.now();
    // Adjust initial date if it conflicts with minDate
    DateTime finalInitial = initial ?? now;
    if (minDate != null && finalInitial.isBefore(minDate)) {
      finalInitial = minDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: finalInitial,
      firstDate: minDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(finalInitial),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_startDateTime == null || _endDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请完善开始和结束时间')),
        );
        return;
      }
      
      if (_endDateTime!.isBefore(_startDateTime!)) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('结束时间不能早于开始时间')),
        );
        return;
      }

      if (_endDateTime!.difference(_startDateTime!).inHours >= 24) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('单场考试时长不能超过24小时')),
        );
        return;
      }
      
      // Generate formatted timeString
      // If same day: YYYY-MM-DD HH:MM~HH:MM
      // If different: YYYY-MM-DD HH:MM ~ YYYY-MM-DD HH:MM (fallback logic might need update, but stick to single line string)
      
      String finalTimeString;
      final start = _startDateTime!;
      final end = _endDateTime!;
      
      final startStr = _formatDateTime(start);
      final endStr = _formatDateTime(end);
      
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
         // Same day
         final datePart = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
         final startTimePart = "${start.hour.toString().padLeft(2,'0')}:${start.minute.toString().padLeft(2,'0')}";
         final endTimePart = "${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}";
         finalTimeString = "$datePart $startTimePart~$endTimePart";
      } else {
         finalTimeString = "$startStr~$endStr"; // Simple join using ~
      }

      final newExam = Exam(
        courseName: _courseName,
        timeString: finalTimeString,
        location: _location,
        type: _typeController.text,
        status: widget.existingExam?.status ?? _status, 
      );

      if (widget.existingExam != null) {
        await ExamService.updateExam(widget.existingExam!, newExam);
      } else {
        await ExamService.addExam(newExam);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExam == null ? '添加考试' : '编辑考试'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _courseName,
                decoration: const InputDecoration(
                  labelText: '课程名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? '请输入课程名称' : null,
                onSaved: (val) => _courseName = val!,
              ),
              const SizedBox(height: 16),
              
              // Start Time
              TextFormField(
                controller: _startDateTimeController,
                readOnly: true,
                onTap: _pickStartDateTime,
                decoration: InputDecoration(
                  labelText: '开始时间',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                validator: (val) => val == null || val.isEmpty ? '请选择开始时间' : null,
              ),
              const SizedBox(height: 16),
              
              // End Time
              TextFormField(
                controller: _endDateTimeController,
                readOnly: true,
                onTap: _pickEndDateTime,
                decoration: InputDecoration(
                  labelText: '结束时间',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time_filled),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                validator: (val) => val == null || val.isEmpty ? '请选择结束时间' : null,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: widget.existingExam?.location ?? '',
                decoration: const InputDecoration(
                  labelText: '地点',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onSaved: (val) => _location = val ?? '',
              ),
              const SizedBox(height: 16),
              
              // Custom Type Input with Chips
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: '类型',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? '请输入或选择类型' : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: ['期末', '补考', '期中', '缓考', '重修'].map((type) {
                  return ActionChip(
                    label: Text(type),
                    onPressed: () {
                      _typeController.text = type;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('保存考试信息'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
