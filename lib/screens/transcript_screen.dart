import 'package:flutter/material.dart';
import '../models/score.dart';
import '../services/score_service.dart';
import 'import_pdf_screen.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  final List<Score> _allScores = [];

  late String _selectedSemester;
  late List<String> _semesters;
  bool _isLoading = true;
  String? _lastImportTime;
  String? _lastImportMethod;

  @override
  void initState() {
    super.initState();
    // 初始化默认值
    _semesters = [];
    _selectedSemester = '无数据';
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await ScoreService.loadScores();
    final importInfo = await ScoreService.loadImportInfo();
    if (!mounted) return;
    
    setState(() {
      _allScores.clear();
      _allScores.addAll(scores);
      _lastImportTime = importInfo['time'];
      _lastImportMethod = importInfo['method'];
      _updateSemesters();
      _isLoading = false;
    });
  }

  void _updateSemesters() {
    _semesters = _allScores.map((e) => e.semester).toSet().toList();
    _semesters.sort((a, b) => b.compareTo(a)); // 倒序排列

    if (_semesters.isNotEmpty) {
      // 保持之前的选择，如果之前选的还在列表里
      if (!_semesters.contains(_selectedSemester)) {
         _selectedSemester = _semesters.first;
      }
    } else {
      _selectedSemester = '无数据';
    }
  }

  // 根据分数计算绩点
  double _getGradePoint(double score) {
    if (score >= 90) return 4.0;
    if (score >= 85) return 3.7;
    if (score >= 82) return 3.3;
    if (score >= 78) return 3.0;
    if (score >= 75) return 2.7;
    if (score >= 71) return 2.3;
    if (score >= 66) return 2.0;
    if (score >= 62) return 1.5;
    if (score >= 60) return 1.0;
    return 0.0;
  }

  // 计算GPA helper
  double _calculateGPA(List<Score> scores) {
    if (scores.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalCredits = 0;
    for (var score in scores) {
      double gp = score.gradePoint;
      totalPoints += gp * score.credit;
      totalCredits += score.credit;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    // 总 GPA 计算
    final totalGPA = _calculateGPA(_allScores);

    // 当前学期数据
    final semesterScores = _allScores
        .where((s) => s.semester == _selectedSemester)
        .toList();
    // 当前学期 GPA 计算
    final semesterGPA = _calculateGPA(semesterScores);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩单'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'pdf') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportPdfScreen(),
                  ),
                );
                
                if (result != null && result is List<Score> && mounted) {
                   final now = DateTime.now();
                   final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                   const methodStr = "PDF文件";

                   setState(() {
                     _allScores.clear();
                     _allScores.addAll(result);
                     _lastImportTime = timeStr;
                     _lastImportMethod = methodStr;
                     _updateSemesters();
                   });
                   await ScoreService.saveScores(_allScores);
                   await ScoreService.saveImportInfo(timeStr, methodStr);
                }
              } else if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有成绩数据吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('确认清空'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ScoreService.clearScores();
                  if (!mounted) return;
                  setState(() {
                    _allScores.clear();
                    _lastImportTime = null;
                    _lastImportMethod = null;
                    _updateSemesters();
                  });
                }
              }
              // TODO: Implement other menu actions
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('从PDF导入'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'jwc',
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text('从教务处导入'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 10),
                      Text('详情'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.grey),
                      SizedBox(width: 10),
                      Text('清空所有数据'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _semesters.isEmpty
          ? const Center(child: Text("暂无成绩数据，点击右上方按钮进行导入"))
          : Column(
              children: [
                // 顶部总览卡片
                _buildOverallCard(totalGPA),

                const SizedBox(height: 16),

                // 学期选择器
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "学期详情",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedSemester,
                        items: _semesters.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedSemester = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 学期 GPA 摘要
                _buildSemesterSummary(semesterGPA, semesterScores),

                const SizedBox(height: 10),

                // 成绩列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
                    itemCount: semesterScores.length,
                    itemBuilder: (context, index) {
                      final score = semesterScores[index];
                      return _buildScoreCard(score);
                    },
                  ),
                ),
                
                // 底部注释
                if (_lastImportTime != null && _lastImportMethod != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "上次导入成绩时间$_lastImportTime，导入方式$_lastImportMethod",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildOverallCard(double totalGPA) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "总平均绩点 (GPA)",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            totalGPA.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSummary(double gpa, List<Score> scores) {
    double totalCredits = 0;
    for (var s in scores) totalCredits += s.credit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildInfoChip(
            label: "学期 GPA",
            value: gpa.toStringAsFixed(2),
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 10),
          _buildInfoChip(
            label: "修读学分",
            value: totalCredits.toStringAsFixed(1),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(Score score) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "学分: ${score.credit}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${score.score.toInt()}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: score.score >= 60 ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  "绩点: ${_getGradePoint(score.score)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
