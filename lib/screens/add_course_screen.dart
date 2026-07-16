import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/time_table.dart';
import '../services/schedule_service.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/l10n/localized_formatters.dart';

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
  CourseStudyType _studyType = CourseStudyType.normal;
  bool _isHidden = false;
  List<TimeDetail> _timeDetails = [];

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
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
      _startWeekController = TextEditingController(
        text: c.startWeek.toString(),
      );
      _endWeekController = TextEditingController(text: c.endWeek.toString());
      _startTimeController = TextEditingController(text: c.startTime ?? '');
      _endTimeController = TextEditingController(text: c.endTime ?? '');

      _day = c.day;
      _startNode = c.startNode;
      _endNode = c.startNode + c.step - 1;
      _type = c.type;
      _selectedColor = c.colorObj;
      _studyType = c.studyType;
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

      final table = tables.firstWhere(
        (t) => t.id == tableId,
        orElse: () => tables.first,
      );
      final details = await ScheduleDataService.loadTimeDetails(
        timeTableId: table.timeTableId,
      );

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
        title: Text(
          widget.course == null
              ? context.l10n.addCourse
              : context.l10n.editCourse,
        ),
        actions: [
          if (widget.course != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCourse,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                _nameController,
                context.l10n.courseName,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(_roomController, context.l10n.classroomLabel),
              const SizedBox(height: 16),
              _buildTextField(_teacherController, context.l10n.instructor),
              const SizedBox(height: 24),

              Text(
                context.l10n.classTime,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _day,
                        decoration: InputDecoration(
                          labelText: context.l10n.weekday,
                        ),
                        items: List.generate(
                          7,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              localizedWeekdayLabel(context.l10n, index + 1),
                            ),
                          ),
                        ).toList(),
                        onChanged: (v) => setState(() => _day = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _startNode,
                              decoration: InputDecoration(
                                labelText: context.l10n.startPeriod,
                              ),
                              isExpanded: true,
                              items: List.generate(15, (index) {
                                final node = index + 1;
                                return DropdownMenuItem(
                                  value: node,
                                  child: Text(
                                    context.l10n.periodNumberWithTime(
                                      node,
                                      _getTimeString(node),
                                    ),
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
                              initialValue: _endNode,
                              decoration: InputDecoration(
                                labelText: context.l10n.endPeriod,
                              ),
                              isExpanded: true,
                              items: List.generate(15, (index) {
                                final node = index + 1;
                                return DropdownMenuItem(
                                  value: node,
                                  child: Text(
                                    context.l10n.periodNumberWithTime(
                                      node,
                                      _getTimeString(node),
                                    ),
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
                              },
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
                              child: _buildTextField(
                                _startTimeController,
                                context.l10n.startTimeHHMm,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _endTimeController,
                              context.l10n.endTimeHHMm,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                context.l10n.weekSettings,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _startWeekController,
                              context.l10n.startWeek,
                              required: true,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _endWeekController,
                              context.l10n.endWeek,
                              required: true,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_type),
                        initialValue: _type,
                        decoration: InputDecoration(
                          labelText: context.l10n.weekPattern,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(context.l10n.everyWeek),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(context.l10n.oddWeeks),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(context.l10n.evenWeeks),
                          ),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                context.l10n.studyStatus,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<CourseStudyType>(
                        key: ValueKey(_studyType),
                        initialValue: _studyType,
                        decoration: InputDecoration(
                          labelText: context.l10n.status,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: CourseStudyType.normal,
                            child: Text(context.l10n.normal),
                          ),
                          DropdownMenuItem(
                            value: CourseStudyType.retake,
                            child: Text(context.l10n.retake2),
                          ),
                          DropdownMenuItem(
                            value: CourseStudyType.exempt,
                            child: Text(context.l10n.attendanceExempt2),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _studyType = v!;
                            if (_studyType != CourseStudyType.exempt) {
                              _isHidden = false;
                            }
                          });
                        },
                      ),
                      if (_studyType == CourseStudyType.exempt) ...[
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: Text(
                            context.l10n.hideThisCourseFromTheSchedule,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            context
                                .l10n
                                .hiddenCoursesAreNotShownInTheScheduleView,
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isHidden,
                          onChanged: (val) {
                            setState(() {
                              _isHidden = val ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                context.l10n.courseColor,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
                        border: _selectedColor == color
                            ? Border.all(color: Colors.grey, width: 3)
                            : null,
                      ),
                      child: _selectedColor == color
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
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
                  child: Text(
                    context.l10n.save,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required
          ? (v) => v == null || v.isEmpty
                ? context.l10n.requiredField(label)
                : null
          : null,
    );
  }

  void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      final startWeek = int.tryParse(_startWeekController.text) ?? 1;
      final endWeek = int.tryParse(_endWeekController.text) ?? 16;

      final colorHex =
          '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

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
        startTime: _startTimeController.text.isNotEmpty
            ? _startTimeController.text
            : null,
        endTime: _endTimeController.text.isNotEmpty
            ? _endTimeController.text
            : null,
        studyType: _studyType,
        isHidden: _isHidden,
      );

      Navigator.pop(context, course);
    }
  }

  void _deleteCourse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteCourse),
        content: Text(
          context.l10n.deleteCourseQuestion(widget.course!.courseName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ScheduleDataService.deleteCourse(widget.course!.id);
              if (mounted) Navigator.pop(context, 'deleted'); // Return signal
            },
            child: Text(
              context.l10n.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
