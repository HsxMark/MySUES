import 'package:flutter/material.dart';
import '../models/exam.dart';

class ExamInfoScreen extends StatefulWidget {
  const ExamInfoScreen({super.key});

  @override
  State<ExamInfoScreen> createState() => _ExamInfoScreenState();
}

class _ExamInfoScreenState extends State<ExamInfoScreen> {
  // Mock data
  final List<Exam> _allExams = [
    Exam(
      courseName: '材料分析方法',
      timeString: '2025-09-05 08:15',
      location: '松江校区 教学楼F楼 F106多 E5',
      type: '补考',
      status: '已结束',
    ),
    Exam(
      courseName: '机器学习',
      timeString: '2025-11-12 12:15~14:15',
      location: '松江校区 教学楼F楼 F320多 L10',
      type: '期末',
      status: '已结束',
    ),
    Exam(
      courseName: '高等数学',
      timeString: '2026-06-15 09:00~11:00',
      location: '松江校区 教学楼A楼 A101',
      type: '期末',
      status: '未结束',
    ),
    Exam(
      courseName: '大学英语',
      timeString: '2026-02-05 13:00~15:00',
      location: '松江校区 教学楼B楼 B202',
      type: '期末',
      status: '未结束',
    ),
  ];

  String _filterStatus = '全部'; // '全部', '未结束', '已结束'

  List<Exam> get _filteredExams {
    // 1. Sort by time (String comparison works for YYYY-MM-DD format)
    _allExams.sort((a, b) => a.timeString.compareTo(b.timeString));

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
