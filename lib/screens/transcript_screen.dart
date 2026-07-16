import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/score.dart';
import '../services/score_service.dart';
import '../services/theme_service.dart';
import '../utils/score_metrics.dart';
import 'transcript_details_screen.dart';
import 'login_webview_screen.dart';
import 'package:mysues/widgets/material_you.dart';
import 'package:mysues/l10n/l10n.dart';

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

  @override
  void initState() {
    super.initState();
    // 初始化默认值
    _semesters = [];
    _selectedSemester = '';
    _loadScores();
    ScoreService.updateNotifier.addListener(_onScoresUpdated);
  }

  @override
  void dispose() {
    ScoreService.updateNotifier.removeListener(_onScoresUpdated);
    super.dispose();
  }

  void _onScoresUpdated() {
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await ScoreService.loadScores();
    final lastImportTime = await ScoreService.loadLastImportTime();
    if (!mounted) return;

    setState(() {
      _allScores.clear();
      _allScores.addAll(scores);
      _lastImportTime = lastImportTime;
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
      _selectedSemester = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 总 GPA 计算
    final totalGPA = ScoreMetrics.calculateGpa(_allScores);

    // 当前学期数据
    final semesterScores = _allScores
        .where((s) => s.semester == _selectedSemester)
        .toList();

    // 当前学期 GPA 计算
    final semesterGPA = ScoreMetrics.calculateGpa(semesterScores);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.grades),
        centerTitle: true,
        backgroundColor: ThemeService().liquidGlassEnabled
            ? Colors.transparent
            : null,
        elevation: ThemeService().liquidGlassEnabled ? 0 : null,
        actions: [
          ListenableBuilder(
            listenable: ThemeService(),
            builder: (context, _) {
              if (ThemeService().liquidGlassEnabled) {
                return IconButton(
                  onPressed: () => _showLiquidGlassMenu(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: context.l10n.menu,
                );
              }
              return MenuAnchor(
                builder:
                    (
                      BuildContext context,
                      MenuController controller,
                      Widget? child,
                    ) {
                      return IconButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        icon: const Icon(Icons.more_vert),
                        tooltip: context.l10n.menu,
                      );
                    },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.sync_alt),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginWebviewScreen(),
                        ),
                      );
                      if (mounted) {
                        await _loadScores();
                      }
                    },
                    child: Text(context.l10n.syncGrades),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TranscriptDetailsScreen(),
                        ),
                      );
                    },
                    child: Text(context.l10n.details),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  MenuItemButton(
                    leadingIcon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(context.l10n.clear),
                          content: Text(
                            context.l10n.clearAllGradeDataThisCannotBeUndone,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(context.l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onError,
                              ),
                              child: Text(context.l10n.clear),
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
                          _updateSemesters();
                        });
                      }
                    },
                    child: Text(
                      context.l10n.clearGrades,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
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
          ? Center(child: Text(context.l10n.noGradesYetImportThemFromTheMenu))
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
                      Text(
                        context.l10n.semester,
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 0,
                    ),
                    itemCount: semesterScores.length,
                    itemBuilder: (context, index) {
                      final score = semesterScores[index];
                      return _buildScoreCard(score);
                    },
                  ),
                ),

                // 底部注释
                if (_lastImportTime != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.l10n.lastImportedAt(_lastImportTime!),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                            label: context.l10n.syncGrades,
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginWebviewScreen(),
                                ),
                              );
                              if (mounted) {
                                await _loadScores();
                              }
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.delete_outline,
                            label: context.l10n.clearGrades,
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(context.l10n.clear),
                                  content: Text(
                                    context
                                        .l10n
                                        .clearAllGradeDataThisCannotBeUndone,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(context.l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text(context.l10n.clear),
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
                                  _updateSemesters();
                                });
                              }
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.info_outline,
                            label: context.l10n.details,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TranscriptDetailsScreen(),
                                ),
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
            Icon(
              icon,
              size: 20,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: IgnorePointer(
              child: Icon(
                Icons.school_rounded,
                size: 96,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.overallGpa,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                ScoreMetrics.formatGpa(totalGPA),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                label: context.l10n.semesterGpa,
                value: ScoreMetrics.formatGpa(gpa),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _buildInfoChip(
                label: context.l10n.credits,
                value: ScoreMetrics.formatCredits(totalCredits),
                color: context.statusColors.warning,
              ),
            ],
          ),
          if (unEvaluatedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AppNoticeBanner(
                message: context.l10n.unevaluatedCoursesExcludedFromGpa(
                  unEvaluatedCount,
                ),
                kind: AppNoticeKind.warning,
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    final isLiquidGlass = ThemeService().liquidGlassEnabled;
    final theme = Theme.of(context);

    final content = Padding(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (score.gradePoint == 0 && score.isEvaluated)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: AppStatusBadge(
                          label: context.l10n.failed,
                          kind: AppStatusKind.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.creditsValue(
                    ScoreMetrics.formatCredits(score.credit),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (score.isEvaluated)
                Text(
                  score.gradePoint.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: score.gradePoint > 0
                        ? context.statusColors.success
                        : theme.colorScheme.error,
                  ),
                )
              else
                Text(
                  context.l10n.pending,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.statusColors.warning,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (isLiquidGlass) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      final isDark = brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            refractiveIndex: 1.21,
            thickness: 30,
            blur: 8,
            saturation: 1.5,
            lightIntensity: isDark ? .7 : 1,
            ambientStrength: isDark ? .2 : .5,
            lightAngle: math.pi / 4,
            glassColor: theme.colorScheme.surface.withValues(alpha: 0.6),
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 36),
          child: Material(color: Colors.transparent, child: content),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(child: content),
    );
  }
}
