import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/score.dart';
import '../services/score_service.dart';
import '../services/theme_service.dart';
import 'import_pdf_screen.dart';
import 'transcript_details_screen.dart';
import 'login_webview_screen.dart';

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
      if (!score.isEvaluated) continue; // 跳过未评教课程
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

    int unEvaluatedCount = semesterScores.where((s) => !s.isEvaluated).length;

    // 当前学期 GPA 计算
    final semesterGPA = _calculateGPA(semesterScores);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩单'),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: ThemeService(),
            builder: (context, _) {
              if (ThemeService().liquidGlassEnabled) {
                return IconButton(
                  onPressed: () => _showLiquidGlassMenu(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: '菜单',
                );
              }
              return MenuAnchor(
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                    tooltip: '菜单',
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.sync_alt),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginWebviewScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        await _loadScores();
                      }
                    },
                    child: const Text('从教务处导入'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    onPressed: () async {
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
                    },
                    child: const Text('从PDF导入'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () async {
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
                    },
                    child: const Text('清空成绩'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.info_outline, color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TranscriptDetailsScreen()),
                      );
                    },
                    child: const Text('详情'),
                  ),
                ],
              );
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

  void _showLiquidGlassMenu(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final baseColor = theme.colorScheme.surface;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss menu',
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight, right: 8),
              child: LiquidGlass.withOwnLayer(
                settings: LiquidGlassSettings(
                  refractiveIndex: 1.21,
                  thickness: 30,
                  blur: 8,
                  saturation: 1.5,
                  lightIntensity: isDark ? .7 : 1,
                  ambientStrength: isDark ? .2 : .5,
                  lightAngle: math.pi / 4,
                  glassColor: baseColor.withValues(alpha: 0.6),
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                child: Material(
                  color: Colors.transparent,
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.sync_alt,
                            label: '从教务处导入',
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginWebviewScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                await _loadScores();
                              }
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.picture_as_pdf,
                            iconColor: Colors.redAccent,
                            label: '从PDF导入',
                            onTap: () async {
                              Navigator.pop(dialogContext);
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
                            },
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.delete_outline,
                            label: '清空成绩',
                            onTap: () async {
                              Navigator.pop(dialogContext);
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
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.info_outline,
                            label: '详情',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TranscriptDetailsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildLiquidGlassMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
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
    int unEvaluatedCount = 0;
    
    for (var s in scores) {
      if (s.isEvaluated) {
        totalCredits += s.credit;
      } else {
        unEvaluatedCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
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
          if (unEvaluatedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                 decoration: BoxDecoration(
                   color: Colors.orange.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.orange.withOpacity(0.3)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         "本学期有 $unEvaluatedCount 门课程未评教，不计入GPA",
                         style: const TextStyle(color: Colors.orange, fontSize: 12),
                       ),
                     ),
                   ],
                 ),
              ),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          score.courseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (score.score < 60 && score.isEvaluated)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: const Text(
                            '挂科',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                if (score.isEvaluated)
                  Text(
                    // 如果是整百/整十可能是转换过的，显示整数即可
                    "${score.score.toInt()}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: score.score >= 60 ? Colors.green : Colors.red,
                    ),
                  )
                else
                  const Text(
                    "未评教",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                if (score.isEvaluated)
                  Text(
                    "绩点: ${score.gradePoint}",
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
