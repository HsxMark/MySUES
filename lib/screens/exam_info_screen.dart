import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';
import '../services/theme_service.dart';
import 'add_exam_screen.dart';
import 'login_webview_screen.dart';

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
    // Listen for updates from other screens (e.g. LoginWebview)
    ExamService.examsUpdateNotifier.addListener(_loadExams);
  }

  @override
  void dispose() {
    ExamService.examsUpdateNotifier.removeListener(_loadExams);
    super.dispose();
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
                      // LoginWebviewScreen returns true if data changed
                      if (result == true && mounted) {
                        await _loadExams();
                      }
                    },
                    child: const Text('从教务处导入'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add, color: Colors.grey),
                    onPressed: () {
                      _navigateToAddExam();
                    },
                    child: const Text('添加自定义考试'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      _clearFinishedExams();
                    },
                    child: const Text('清除已结束'),
                  ),
                ],
              );
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
                                await _loadExams();
                              }
                            },
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.add,
                            label: '添加自定义考试',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _navigateToAddExam();
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.delete_outline,
                            label: '清除已结束',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _clearFinishedExams();
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

  Future<void> _clearFinishedExams() async {
    await ExamService.clearFinishedExams();
    _loadExams();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除所有已结束的考试')),
      );
    }
  }

  void _navigateToAddExam({Exam? existingExam}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddExamScreen(existingExam: existingExam),
      ),
    );

    if (result == true) {
      _loadExams();
    }
  }

  void _showExamDetails(Exam exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isLiquidGlass = ThemeService().liquidGlassEnabled;
        final theme = Theme.of(context);

        Widget sheet = Container(
          decoration: isLiquidGlass ? null : BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.only(top: 8),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // Handle bar
               Center(
                 child: Container(
                   width: 40, 
                   height: 5, 
                   decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.5)),
                 ),
               ),
               // Top buttons
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     TextButton(
                       onPressed: () async {
                          // Confirm delete
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('删除后无法恢复，是否继续？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ExamService.deleteExam(exam);
                          if (mounted) {
                            Navigator.pop(context); // Close bottom sheet
                            _loadExams();
                          }
                        }
                       },
                       child: const Text('删除', style: TextStyle(color: Colors.red, fontSize: 16)),
                     ),
                     TextButton(
                       onPressed: () {
                         Navigator.pop(context);
                         _navigateToAddExam(existingExam: exam);
                       },
                       child: const Text('编辑', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                     ),
                   ],
                 ),
               ),
               // Title
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
                 child: Text(
                   exam.courseName,
                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                 ),
               ),
               // Sub headers
                Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: const [
                     Text("详情", style: TextStyle(color: Colors.grey)),
                     Text("以下内容可长按复制", style: TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 ),
               ),
               
               // Info Card
               Expanded(
                 child: SingleChildScrollView(
                   child: Column(
                     children: [
                       Container(
                         margin: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(
                           color: Theme.of(context).cardColor,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           children: [
                             _buildDetailRow(
                               icon: Icons.access_time, 
                               content: exam.timeString,
                               color: Colors.redAccent
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildDetailRow(
                               icon: Icons.location_on_outlined, 
                               content: exam.location,
                               color: Colors.redAccent
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildDetailRow(
                               icon: Icons.category_outlined,
                               content: exam.type,
                               color: Colors.redAccent
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildDetailRow(
                               icon: Icons.info_outline,
                               content: exam.status,
                               color: Colors.redAccent
                             ),
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 16),
                       // Actions Card
                        Container(
                         margin: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(
                           color: Theme.of(context).cardColor,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           children: [
                             _buildActionRow(
                               icon: Icons.copy, 
                               text: '复制考试名称',
                               color: Colors.redAccent,
                               onTap: () {
                                 Clipboard.setData(ClipboardData(text: exam.courseName));
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制考试名称')));
                               }
                             ),
                             const Divider(height: 1, indent: 56),
                             _buildActionRow(
                               icon: Icons.copy, 
                               text: '复制考试信息为文本',
                               color: Colors.redAccent,
                               onTap: () {
                                 final info = '${exam.courseName}\n时间: ${exam.timeString}\n地点: ${exam.location}';
                                 Clipboard.setData(ClipboardData(text: info));
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制考试信息')));
                               }
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 30),
                     ],
                   ),
                 ),
               ),
            ],
          ),
        );

        if (isLiquidGlass) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          final isDark = brightness == Brightness.dark;
          sheet = LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings.figma(
              depth: 50,
              refraction: 100,
              dispersion: 4,
              frost: 2,
              lightAngle: math.pi / 4,
              glassColor: theme.colorScheme.surface.withValues(alpha: 0.8),
              lightIntensity: isDark ? 70 : 50,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            child: Material(
              color: Colors.transparent,
              child: sheet,
            ),
          );
        }

        return sheet;
      },
    );
  }

  Widget _buildDetailRow({required IconData icon, required String content, required Color color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(content, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onLongPress: () {
         Clipboard.setData(ClipboardData(text: content));
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
      },
    );
  }
  
  Widget _buildActionRow({required IconData icon, required String text, required Color color, VoidCallback? onTap}) {
       return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: const TextStyle(fontSize: 16, color: Colors.redAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
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
    
    return InkWell(
      onTap: () => _showExamDetails(exam),
      child: Card(
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
