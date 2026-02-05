import 'package:flutter/material.dart';
import '../services/course_storage_service.dart';

/// 学期设置界面
class SemesterSettingsScreen extends StatefulWidget {
  const SemesterSettingsScreen({super.key});

  @override
  State<SemesterSettingsScreen> createState() => _SemesterSettingsScreenState();
}

class _SemesterSettingsScreenState extends State<SemesterSettingsScreen> {
  DateTime? _semesterStartDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final startDate = await CourseStorageService.loadSemesterStartDate();

    setState(() {
      _semesterStartDate = startDate;
      _isLoading = false;
    });
  }

  /// 选择学期开始日期
  Future<void> _selectSemesterStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _semesterStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '选择学期开始日期',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (picked != null) {
      // 获取该日期所在周的周一
      final weekday = picked.weekday;
      final monday = picked.subtract(Duration(days: weekday - 1));

      await CourseStorageService.saveSemesterStartDate(monday);
      setState(() {
        _semesterStartDate = monday;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '学期开始日期已设置为：${monday.year}年${monday.month}月${monday.day}日（第1周周一）',
            ),
          ),
        );
      }
    }
  }

  /// 计算当前是第几周
  int? _getCurrentWeekNumber() {
    if (_semesterStartDate == null) return null;

    final now = DateTime.now();
    final daysSinceStart = now.difference(_semesterStartDate!).inDays;
    final weekNumber = (daysSinceStart / 7).floor() + 1;

    if (weekNumber < 1 || weekNumber > 20) return null;
    return weekNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学期设置'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '学期说明',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• 一学期共20周\n'
                          '• 请设置第1周的开始日期（周一）\n'
                          '• 系统会自动计算当前周次\n'
                          '• 添加课程时可选择1-20周',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('学期开始日期'),
                    subtitle: Text(
                      _semesterStartDate == null
                          ? '未设置（点击设置）'
                          : '${_semesterStartDate!.year}年${_semesterStartDate!.month}月${_semesterStartDate!.day}日（第1周周一）',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectSemesterStartDate,
                  ),
                ),
                if (_semesterStartDate != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                '当前周次',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCurrentWeekNumber() != null
                                ? '第 ${_getCurrentWeekNumber()} 周'
                                : '不在学期范围内',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getCurrentWeekNumber() != null
                                  ? Colors.blue[700]
                                  : Colors.red[700],
                            ),
                          ),
                          if (_getCurrentWeekNumber() == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '当前日期不在第1-20周范围内',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_semesterStartDate == null)
                  ElevatedButton.icon(
                    onPressed: _selectSemesterStartDate,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('设置学期开始日期'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
    );
  }
}
