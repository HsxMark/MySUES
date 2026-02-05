import 'package:flutter/material.dart';
import '../models/course.dart';

class AddCourseScreenV2 extends StatefulWidget {
  final Course? course; // 编辑模式传入对象

  const AddCourseScreenV2({super.key, this.course});

  @override
  State<AddCourseScreenV2> createState() => _AddCourseScreenV2State();
}

class _AddCourseScreenV2State extends State<AddCourseScreenV2> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _roomController;
  late TextEditingController _teacherController;
  late TextEditingController _startWeekController;
  late TextEditingController _endWeekController;

  // State variables
  int _day = 1; // 1-7
  int _startNode = 1;
  int _step = 2;
  int _type = 0; // 0: All, 1: Odd, 2: Even
  Color _selectedColor = Colors.blue;

  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    Colors.cyan, Colors.brown
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (widget.course != null) {
      final c = widget.course!;
      _nameController = TextEditingController(text: c.courseName);
      _roomController = TextEditingController(text: c.room);
      _teacherController = TextEditingController(text: c.teacher);
      _startWeekController = TextEditingController(text: c.startWeek.toString());
      _endWeekController = TextEditingController(text: c.endWeek.toString());
      
      _day = c.day;
      _startNode = c.startNode;
      _step = c.step;
      _type = c.type;
      _selectedColor = c.colorObj;
    } else {
      _nameController = TextEditingController();
      _roomController = TextEditingController();
      _teacherController = TextEditingController();
      _startWeekController = TextEditingController(text: '1');
      _endWeekController = TextEditingController(text: '16');
      _selectedColor = _colors[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    _startWeekController.dispose();
    _endWeekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? '添加课程' : '编辑课程'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, '课程名称', required: true),
              const SizedBox(height: 16),
              _buildTextField(_roomController, '教室'),
              const SizedBox(height: 16),
              _buildTextField(_teacherController, '老师'),
              const SizedBox(height: 24),
              
              const Text('上课时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                           Expanded(
                             child: DropdownButtonFormField<int>(
                               value: _day,
                               decoration: const InputDecoration(labelText: '星期'),
                               items: List.generate(7, (index) => DropdownMenuItem(
                                 value: index + 1,
                                 child: Text(['周一','周二','周三','周四','周五','周六','周日'][index]),
                               )).toList(),
                               onChanged: (v) => setState(() => _day = v!),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: DropdownButtonFormField<int>(
                               value: _startNode,
                               decoration: const InputDecoration(labelText: '开始节次'),
                               items: List.generate(12, (index) => DropdownMenuItem(
                                 value: index + 1,
                                 child: Text('第 ${index + 1} 节'),
                               )).toList(),
                               onChanged: (v) => setState(() => _startNode = v!),
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                         value: _step,
                         decoration: const InputDecoration(labelText: '持续节数'),
                         items: [1, 2, 3, 4].map((e) => DropdownMenuItem(
                           value: e,
                           child: Text('$e 节'),
                         )).toList(),
                         onChanged: (v) => setState(() => _step = v!),
                       ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('周次设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_startWeekController, '开始周', required: true, isNumber: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_endWeekController, '结束周', required: true, isNumber: true)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                         value: _type,
                         decoration: const InputDecoration(labelText: '单双周'),
                         items: const [
                           DropdownMenuItem(value: 0, child: Text('每周')),
                           DropdownMenuItem(value: 1, child: Text('单周')),
                           DropdownMenuItem(value: 2, child: Text('双周')),
                         ],
                         onChanged: (v) => setState(() => _type = v!),
                       ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text('课程颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color ? Border.all(color: Colors.grey, width: 3) : null,
                      ),
                      child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saveCourse,
                  child: const Text('保存', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => v == null || v.isEmpty ? '请输入$label' : null : null,
    );
  }

  void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      final startWeek = int.tryParse(_startWeekController.text) ?? 1;
      final endWeek = int.tryParse(_endWeekController.text) ?? 16;
      
      final colorHex = '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

      final course = Course(
        id: widget.course?.id ?? 0,
        courseName: _nameController.text,
        day: _day,
        room: _roomController.text,
        teacher: _teacherController.text,
        startNode: _startNode,
        step: _step,
        startWeek: startWeek,
        endWeek: endWeek,
        type: _type,
        color: colorHex,
        tableId: widget.course?.tableId ?? 0, // Should be passed or default
      );

      Navigator.pop(context, course);
    }
  }
}
