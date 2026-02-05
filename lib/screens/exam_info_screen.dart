import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';
import 'add_exam_screen.dart';

class ExamInfoScreen extends StatefulWidget {
  const ExamInfoScreen({super.key});

  @override
  State<ExamInfoScreen> createState() => _ExamInfoScreenState();
}

class _ExamInfoScreenState extends State<ExamInfoScreen> {
  // Data list
  List<Exam> _allExams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = await ExamService.loadExams();
    if (mounted) {
      setState(() {
        _allExams = exams;
      });
    }
  }

  String _filterStatus = '全部';

  List<Exam> get _filteredExams {
    _allExams.sort((a, b) {
      final bool aFinished = a.status == '已结束';
      final bool bFinished = b.status == '已结束';

      // Put unfinished exams before finished exams
      if (aFinished != bFinished) {
        return aFinished ? 1 : -1;
      }

      // If both are unfinished, sort ascending (closer to today first)
      if (!aFinished) {
        return a.timeString.compareTo(b.timeString);
      }

      // If both are finished, sort descending (closer to today first)
      return b.timeString.compareTo(a.timeString);
    });

    // 2. Filter
    if (_filterStatus == '全部') {
      return _allExams;
    }
    return _allExams.where((exam) => exam.status == _filterStatus).toList();
  }

  bool _isToday(String timeString) {
    if (timeString.isEmpty) return false;
    // Extract YYYY-MM-DD
    try {
      final datePart = timeString.substring(0, 10);
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return datePart == todayStr;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayExams = _filteredExams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('考试信息'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _navigateToAddExam();
                  break;
                case 'clear':
                  _clearFinishedExams();
                  break;
                case 'details':
                  // Placeholder
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'add',
                  child: Text('添加自定义考试'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('清除已结束'),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Text('详情'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer
          Container(
            width: double.infinity,
            color: Colors.red[50],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    '考试信息仅供参考，请以教务处系统提示为准',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text('筛选: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildFilterChip('全部'),
                const SizedBox(width: 8),
                _buildFilterChip('未结束'),
                const SizedBox(width: 8),
                _buildFilterChip('已结束'),
              ],
            ),
          ),

          // List
          Expanded(
            child: displayExams.isEmpty
                ? const Center(child: Text('暂无符合条件的考试信息'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: displayExams.length,
                    itemBuilder: (context, index) {
                      final exam = displayExams[index];
                      return _buildExamCard(exam);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearFinishedExams() async {
    await ExamService.clearFinishedExams();
    _loadExams();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除所有已结束的考试')),
      );
    }
  }

  void _navigateToAddExam() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddExamScreen(),
      ),
    );

    if (result == true) {
      _loadExams();
    }
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == label,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _filterStatus = label;
          });
        }
      },
    );
  }

  Widget _buildExamCard(Exam exam) {
    final bool isTodayExam = _isToday(exam.timeString);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isTodayExam ? Colors.yellow[100] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTodayExam ? const BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exam.courseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(exam.status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time, '时间', exam.timeString),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, '地点', exam.location),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category_outlined, '类型', exam.type),
            if (isTodayExam) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '今日考试，请注意时间！',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == '已结束') {
      color = Colors.grey;
    } else if (status == '未结束' || status == '进行中') {
      color = Colors.blue; 
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
