import 'package:flutter/material.dart';
import '../models/course_item.dart';

/// 添加/编辑课程界面
class AddCourseScreen extends StatefulWidget {
  final CourseItem? course; // 如果不为空，则为编辑模式
  final int? courseIndex; // 编辑时的课程索引

  const AddCourseScreen({super.key, this.course, this.courseIndex});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _teacherController;
  late TextEditingController _locationController;
  late TextEditingController _weekNumbersController;

  String _selectedType = '必修';
  int _selectedWeekday = 1; // 1=周一
  int _startSlot = 1; // 第几节课开始
  int _courseCount = 2; // 持续节数
  Color _selectedColor = Colors.blue[200]!;

  // 可选的课程类型
  final List<String> _courseTypes = ['必修', '选修', '公选', '实验', '其他'];

  // 可选颜色
  final List<Color> _availableColors = [
    Colors.blue[200]!,
    Colors.green[200]!,
    Colors.orange[200]!,
    Colors.purple[200]!,
    Colors.pink[200]!,
    Colors.teal[200]!,
    Colors.amber[200]!,
    Colors.cyan[200]!,
    Colors.lime[200]!,
    Colors.indigo[200]!,
  ];

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _titleController = TextEditingController(text: widget.course?.title ?? '');
    _teacherController = TextEditingController(
      text: widget.course?.teacher ?? '',
    );
    _locationController = TextEditingController(
      text: widget.course?.location ?? '',
    );
    _weekNumbersController = TextEditingController(
      text: widget.course?.weekNumbers.join(',') ?? '',
    );

    // 如果是编辑模式，加载现有数据
    if (widget.course != null) {
      _selectedType = widget.course!.type;
      _selectedWeekday = widget.course!.startTime.weekday;
      _courseCount = widget.course!.count;
      _selectedColor = widget.course!.color;
      _startSlot = _calculateStartSlot(widget.course!.startTime);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _weekNumbersController.dispose();
    super.dispose();
  }

  /// 根据时间计算开始节次
  int _calculateStartSlot(DateTime time) {
    final slots = [
      (8, 15),
      (8, 55),
      (9, 55),
      (10, 35),
      (11, 20),
      (13, 20),
      (14, 0),
      (15, 0),
      (15, 40),
      (16, 35),
      (17, 15),
      (18, 10),
      (18, 50),
      (19, 35),
      (20, 20),
    ];

    for (int i = 0; i < slots.length; i++) {
      if (time.hour == slots[i].$1 && time.minute == slots[i].$2) {
        return i + 1;
      }
    }
    return 1;
  }

  /// 根据节次计算开始时间
  (int, int) _getTimeBySlot(int slot) {
    final slots = [
      (8, 15),
      (8, 55),
      (9, 55),
      (10, 35),
      (11, 20),
      (13, 20),
      (14, 0),
      (15, 0),
      (15, 40),
      (16, 35),
      (17, 15),
      (18, 10),
      (18, 50),
      (19, 35),
      (20, 20),
    ];

    if (slot < 1 || slot > slots.length) return (8, 15);
    return slots[slot - 1];
  }

  /// 根据节次计算结束时间
  (int, int) _getEndTimeBySlot(int startSlot, int count) {
    final endTimes = [
      (8, 55),
      (9, 35),
      (10, 35),
      (11, 15),
      (12, 0),
      (14, 0),
      (14, 40),
      (15, 40),
      (16, 20),
      (17, 15),
      (17, 55),
      (18, 50),
      (19, 30),
      (20, 15),
      (21, 0),
    ];

    final endSlot = startSlot + count - 1;
    if (endSlot < 1 || endSlot > endTimes.length) return (9, 35);
    return endTimes[endSlot - 1];
  }

  /// 解析周次输入
  List<int> _parseWeekNumbers(String input) {
    if (input.trim().isEmpty) return [];

    final List<int> weeks = [];
    final parts = input.split(',');

    for (var part in parts) {
      part = part.trim();
      if (part.contains('-')) {
        // 范围：如 "1-5"
        final range = part.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              if (!weeks.contains(i)) weeks.add(i);
            }
          }
        }
      } else {
        // 单个周次
        final week = int.tryParse(part);
        if (week != null && !weeks.contains(week)) {
          weeks.add(week);
        }
      }
    }

    weeks.sort();
    return weeks;
  }

  /// 保存课程
  void _saveCourse() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 解析周次
    final weekNumbers = _parseWeekNumbers(_weekNumbersController.text);
    if (weekNumbers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的上课周次')));
      return;
    }

    // 计算开始和结束时间
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final courseDate = weekStart.add(Duration(days: _selectedWeekday - 1));

    final startTime = _getTimeBySlot(_startSlot);
    final endTime = _getEndTimeBySlot(_startSlot, _courseCount);

    final startDateTime = DateTime(
      courseDate.year,
      courseDate.month,
      courseDate.day,
      startTime.$1,
      startTime.$2,
    );

    final endDateTime = DateTime(
      courseDate.year,
      courseDate.month,
      courseDate.day,
      endTime.$1,
      endTime.$2,
    );

    final course = CourseItem(
      title: _titleController.text.trim(),
      type: _selectedType,
      location: _locationController.text.trim(),
      teacher: _teacherController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      count: _courseCount,
      color: _selectedColor,
      weekNumbers: weekNumbers,
    );

    Navigator.pop(context, {'course': course, 'index': widget.courseIndex});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? '添加课程' : '编辑课程'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveCourse),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 课程标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '课程标题',
                hintText: '请输入课程名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入课程标题';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 教学老师
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '教学老师',
                hintText: '请输入老师姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            // 上课地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点',
                hintText: '请输入教室或地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

            // 课程类型
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '课程类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _courseTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // 上课周次
            TextFormField(
              controller: _weekNumbersController,
              decoration: const InputDecoration(
                labelText: '上课周次',
                hintText: '如：1,2,3 或 1-5,7,9-12',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: '支持单个周次(1,2,3)或范围(1-5)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入上课周次';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 星期选择
            DropdownButtonFormField<int>(
              initialValue: _selectedWeekday,
              decoration: const InputDecoration(
                labelText: '星期',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('周一')),
                DropdownMenuItem(value: 2, child: Text('周二')),
                DropdownMenuItem(value: 3, child: Text('周三')),
                DropdownMenuItem(value: 4, child: Text('周四')),
                DropdownMenuItem(value: 5, child: Text('周五')),
                DropdownMenuItem(value: 6, child: Text('周六')),
                DropdownMenuItem(value: 7, child: Text('周日')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedWeekday = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // 开始节次
            DropdownButtonFormField<int>(
              initialValue: _startSlot,
              decoration: const InputDecoration(
                labelText: '开始节次',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              items: List.generate(15, (index) {
                final slot = index + 1;
                final time = _getTimeBySlot(slot);
                return DropdownMenuItem(
                  value: slot,
                  child: Text(
                    '第$slot节 (${time.$1.toString().padLeft(2, '0')}:${time.$2.toString().padLeft(2, '0')})',
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _startSlot = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // 持续节数
            DropdownButtonFormField<int>(
              initialValue: _courseCount,
              decoration: const InputDecoration(
                labelText: '持续节数',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              items: List.generate(8, (index) {
                final count = index + 1;
                return DropdownMenuItem(value: count, child: Text('$count节课'));
              }),
              onChanged: (value) {
                setState(() {
                  _courseCount = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // 颜色选择
            const Text(
              '课程颜色',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // 预览信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '课程预览',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '时间：第$_startSlot节 - 第${_startSlot + _courseCount - 1}节',
                    ),
                    const SizedBox(height: 4),
                    Text('周次：${_weekNumbersController.text}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
