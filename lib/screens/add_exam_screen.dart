import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _courseName = '';
  String _timeString = '';
  String _location = '';
  String _type = '期末';
  final String _status = '未结束'; // Default new exams are unfinished

  // Date/Time picker helpers could be added here later for better UX
  // For now, we'll stick to text input as per the previous dialog implementation

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newExam = Exam(
        courseName: _courseName,
        timeString: _timeString,
        location: _location,
        type: _type,
        status: _status,
      );

      await ExamService.addExam(newExam);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加考试'),
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
                decoration: const InputDecoration(
                  labelText: '课程名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? '请输入课程名称' : null,
                onSaved: (val) => _courseName = val!,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '时间 (e.g., 2026-06-15 09:00)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  helperText: '建议格式: YYYY-MM-DD HH:MM',
                ),
                validator: (val) => val == null || val.isEmpty ? '请输入时间' : null,
                onSaved: (val) => _timeString = val!,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '地点',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onSaved: (val) => _location = val ?? '',
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: '类型',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ['期末', '补考', '其他']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _type = val!),
                onSaved: (val) => _type = val!,
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
