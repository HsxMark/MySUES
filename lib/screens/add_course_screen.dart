import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/time_table.dart';
import '../services/schedule_service.dart';

class AddCourseScreen extends StatefulWidget {
  final Course? course; // 编辑模式传入对象

  const AddCourseScreen({super.key, this.course});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _roomController;
  late TextEditingController _teacherController;
  late TextEditingController _startWeekController;
  late TextEditingController _endWeekController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  // State variables
  int _day = 1; // 1-7
  int _startNode = 1;
  int _endNode = 2; 
  int _type = 0; // 0: All, 1: Odd, 2: Even
  Color _selectedColor = Colors.blue;
  List<TimeDetail> _timeDetails = [];

  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    Colors.cyan, Colors.brown
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    _loadTimeDetails();
  }

  void _initData() {
    if (widget.course != null) {
      final c = widget.course!;
      _nameController = TextEditingController(text: c.courseName);
      _roomController = TextEditingController(text: c.room);
      _teacherController = TextEditingController(text: c.teacher);
      _startWeekController = TextEditingController(text: c.startWeek.toString());
      _endWeekController = TextEditingController(text: c.endWeek.toString());
      _startTimeController = TextEditingController(text: c.startTime ?? '');
      _endTimeController = TextEditingController(text: c.endTime ?? '');
      
      _day = c.day;
      _startNode = c.startNode;
      _endNode = c.startNode + c.step - 1;
      _type = c.type;
      _selectedColor = c.colorObj;
    } else {
      _nameController = TextEditingController();
      _roomController = TextEditingController();
      _teacherController = TextEditingController();
      _startWeekController = TextEditingController(text: '1');
      _endWeekController = TextEditingController(text: '16');
      _startTimeController = TextEditingController();
      _endTimeController = TextEditingController();
      _selectedColor = _colors[0];
      _startNode = 1;
      _endNode = 2;
    }
  }

  Future<void> _loadTimeDetails() async {
    try {
      int tableId = widget.course?.tableId ?? 0;
      if (tableId == 0) {
        tableId = await ScheduleDataService.getCurrentTableId();
      }
      
      final tables = await ScheduleDataService.loadScheduleTables();
      if (tables.isEmpty) return;
      
      final table = tables.firstWhere((t) => t.id == tableId, orElse: () => tables.first);
      final details = await ScheduleDataService.loadTimeDetails(timeTableId: table.timeTableId);
      
      if (mounted) {
        setState(() {
          _timeDetails = details;
          // Init time text if empty
          if (_startTimeController.text.isEmpty && _timeDetails.isNotEmpty) {
             _updateTimeFromNodes();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading time details: $e');
    }
  }

  void _updateTimeFromNodes() {
    if (_timeDetails.isEmpty) return;
    try {
      final start = _timeDetails.firstWhere((d) => d.node == _startNode);
      final end = _timeDetails.firstWhere((d) => d.node == _endNode);
      _startTimeController.text = start.startTime;
      _endTimeController.text = end.endTime;
    } catch (_) {}
  }
  
  String _getTimeString(int node) {
    if (_timeDetails.isEmpty) return '';
    try {
      final detail = _timeDetails.firstWhere((d) => d.node == node);
      return '(${detail.startTime}-${detail.endTime})';
    } catch (e) {
      return '';
    }
  }

  String _getTimeRangeDisplay() {
    if (_timeDetails.isEmpty) return '';
    try {
      final start = _timeDetails.firstWhere((d) => d.node == _startNode);
      final end = _timeDetails.firstWhere((d) => d.node == _endNode);
      return '${start.startTime} - ${end.endTime}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    _startWeekController.dispose();
    _endWeekController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? '添加课程' : '编辑课程'),
        actions: [
          if (widget.course != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCourse,
            )
        ],
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _day,
                        decoration: const InputDecoration(labelText: '星期'),
                        items: List.generate(7, (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(['周一','周二','周三','周四','周五','周六','周日'][index]),
                        )).toList(),
                        onChanged: (v) => setState(() => _day = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                           Expanded(
                             child: DropdownButtonFormField<int>(
                               value: _startNode,
                               decoration: const InputDecoration(labelText: '开始节次'),
                               isExpanded: true,
                               items: List.generate(15, (index) {
                                 final node = index + 1;
                                 return DropdownMenuItem(
                                   value: node,
                                   child: Text(
                                     '第 $node 节 ${_getTimeString(node)}',
                                     style: const TextStyle(fontSize: 12),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 );
                               }).toList(),
                               onChanged: (v) {
                                 setState(() {
                                    _startNode = v!;
                                    if (_endNode < _startNode) {
                                      _endNode = _startNode;
                                    }
                                    _updateTimeFromNodes();
                                 });
                               },
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: DropdownButtonFormField<int>(
                               value: _endNode,
                               decoration: const InputDecoration(labelText: '结束节次'),
                               isExpanded: true,
                               items: List.generate(15, (index) {
                                 final node = index + 1;
                                 return DropdownMenuItem(
                                   value: node,
                                   child: Text(
                                     '第 $node 节 ${_getTimeString(node)}',
                                     style: const TextStyle(fontSize: 12),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 );
                               }).toList(),
                               onChanged: (v) {
                                  setState(() {
                                     _endNode = v!; 
                                     if (_endNode < _startNode) {
                                       _startNode = _endNode;
                                     }
                                     _updateTimeFromNodes();
                                  });
                               }
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                         children: [
                           Expanded(
                             child: GestureDetector(
                               onTap: () async {
                                 // Optional: Add TimePicker here
                               },
                               child: _buildTextField(_startTimeController, '开始时间(HH:mm)'),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(child: _buildTextField(_endTimeController, '结束时间(HH:mm)')),
                         ],
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                         key: ValueKey(_type),
                         initialValue: _type,
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
      
      final colorHex = '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      
      final step = _endNode - _startNode + 1;

      final course = Course(
        id: widget.course?.id ?? 0,
        courseName: _nameController.text,
        day: _day,
        room: _roomController.text,
        teacher: _teacherController.text,
        startNode: _startNode,
        step: step,
        startWeek: startWeek,
        endWeek: endWeek,
        type: _type,
        color: colorHex,
        tableId: widget.course?.tableId ?? 0, // Should be passed or default
        startTime: _startTimeController.text.isNotEmpty ? _startTimeController.text : null,
        endTime: _endTimeController.text.isNotEmpty ? _endTimeController.text : null,
      );

      Navigator.pop(context, course);
    }
  }

  void _deleteCourse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确认要删除课程 "${widget.course!.courseName}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ScheduleDataService.deleteCourse(widget.course!.id);
              if (mounted) Navigator.pop(context, 'deleted'); // Return signal
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }
}
