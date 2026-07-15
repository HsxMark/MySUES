import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';
import '../services/theme_service.dart';
import 'add_exam_screen.dart';
import 'login_webview_screen.dart';
import '../utils/sync_disclaimer.dart';
import 'package:mysues/l10n/exam_text.dart';
import 'package:mysues/widgets/material_you.dart';
import 'package:mysues/l10n/l10n.dart';

enum _ExamFilter { all, unfinished, finished }

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

  Future<void> _importFromAcademic() async {
    final screenContext = context;
    if (!await showSyncDisclaimer(screenContext)) return;
    if (!screenContext.mounted) return;

    final result = await Navigator.of(screenContext).push<bool>(
      MaterialPageRoute(builder: (context) => const LoginWebviewScreen()),
    );

    if (result == true && screenContext.mounted) {
      await _loadExams();
      if (!screenContext.mounted) return;
      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(content: Text(context.l10n.examScheduleImported)),
      );
    }
  }

  _ExamFilter _filter = _ExamFilter.all;

  List<Exam> get _filteredExams {
    _allExams.sort((a, b) {
      final bool aFinished = isFinishedExamStatus(a.status);
      final bool bFinished = isFinishedExamStatus(b.status);

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
    return switch (_filter) {
      _ExamFilter.all => _allExams,
      _ExamFilter.unfinished =>
        _allExams.where((exam) => !isFinishedExamStatus(exam.status)).toList(),
      _ExamFilter.finished =>
        _allExams.where((exam) => isFinishedExamStatus(exam.status)).toList(),
    };
  }

  bool _isToday(String timeString) {
    if (timeString.isEmpty) return false;
    // Extract YYYY-MM-DD
    try {
      final datePart = timeString.substring(0, 10);
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
        title: Text(context.l10n.examInformation),
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
                    onPressed: _importFromAcademic,
                    child: Text(context.l10n.syncExam),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add),
                    onPressed: () {
                      _navigateToAddExam();
                    },
                    child: Text(context.l10n.addExam),
                  ),
                  const Divider(indent: 12, endIndent: 12),
                  MenuItemButton(
                    leadingIcon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      _clearFinishedExams();
                    },
                    child: Text(
                      context.l10n.clearFinished,
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
      body: Column(
        children: [
          AppNoticeBanner(
            message: context.l10n.examInformationMayNotBeCurrentAlwaysConfirmIt,
            kind: AppNoticeKind.warning,
          ),

          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Text(
                  context.l10n.filter,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                MenuAnchor(
                  builder:
                      (
                        BuildContext context,
                        MenuController controller,
                        Widget? child,
                      ) => OutlinedButton.icon(
                        onPressed: () => controller.isOpen
                            ? controller.close()
                            : controller.open(),
                        icon: const Icon(Icons.filter_list),
                        label: Text(_filterLabel(context, _filter)),
                      ),
                  menuChildren: _ExamFilter.values.map((filter) {
                    final selected = _filter == filter;
                    return MenuItemButton(
                      leadingIcon: Icon(
                        selected ? Icons.check : _filterIcon(filter),
                      ),
                      onPressed: () => setState(() => _filter = filter),
                      child: Text(_filterLabel(context, filter)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: displayExams.isEmpty
                ? Center(child: Text(context.l10n.noMatchingExams))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
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
                            label: context.l10n.syncExam,
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              await _importFromAcademic();
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
                            icon: Icons.add,
                            label: context.l10n.addExam,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _navigateToAddExam();
                            },
                          ),
                          _buildLiquidGlassMenuItem(
                            context: dialogContext,
                            icon: Icons.delete_outline,
                            label: context.l10n.clearFinished,
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

  Future<void> _clearFinishedExams() async {
    await ExamService.clearFinishedExams();
    _loadExams();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.allFinishedExamsWereCleared)),
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
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isLiquidGlass = ThemeService().liquidGlassEnabled;
        final theme = Theme.of(context);

        Widget sheet = Container(
          decoration: isLiquidGlass
              ? null
              : BoxDecoration(
                  color: theme.colorScheme.surface,
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
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              // Top buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        // Confirm delete
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.l10n.confirmDeletion),
                            content: Text(
                              context.l10n.thisCannotBeUndoneContinue,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(context.l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  context.l10n.delete,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
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
                      child: Text(
                        context.l10n.delete,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAddExam(existingExam: exam);
                      },
                      child: Text(
                        context.l10n.edit,
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 4,
                ),
                child: Text(
                  exam.courseName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Sub headers
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.details,
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      context.l10n.pressAndHoldToCopyTheContentBelow,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
                              color: Colors.redAccent,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildDetailRow(
                              icon: Icons.location_on_outlined,
                              content: exam.location,
                              color: Colors.redAccent,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildDetailRow(
                              icon: Icons.category_outlined,
                              content: localizedExamType(context, exam.type),
                              copyContent: exam.type,
                              color: Colors.redAccent,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildDetailRow(
                              icon: Icons.info_outline,
                              content: localizedExamStatus(
                                context,
                                exam.status,
                              ),
                              copyContent: exam.status,
                              color: Colors.redAccent,
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
                              text: context.l10n.copyExamName,
                              color: Colors.redAccent,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: exam.courseName),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.examNameCopied),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildActionRow(
                              icon: Icons.copy,
                              text: context.l10n.copyExamDetailsAsText,
                              color: Colors.redAccent,
                              onTap: () {
                                final info = context.l10n.examCopyText(
                                  exam.courseName,
                                  exam.timeString,
                                  exam.location,
                                );
                                Clipboard.setData(ClipboardData(text: info));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.examDetailsCopied,
                                    ),
                                  ),
                                );
                              },
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
            child: Material(color: Colors.transparent, child: sheet),
          );
        }

        return sheet;
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String content,
    String? copyContent,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(content, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: copyContent ?? content));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
      },
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  String _filterLabel(BuildContext context, _ExamFilter filter) =>
      switch (filter) {
        _ExamFilter.all => context.l10n.all,
        _ExamFilter.unfinished => context.l10n.upcoming,
        _ExamFilter.finished => context.l10n.finished,
      };

  IconData _filterIcon(_ExamFilter filter) => switch (filter) {
    _ExamFilter.all => Icons.list_alt_outlined,
    _ExamFilter.unfinished => Icons.upcoming_outlined,
    _ExamFilter.finished => Icons.event_available_outlined,
  };

  Widget _buildExamCard(Exam exam) {
    final bool isTodayExam = _isToday(exam.timeString);
    final isLiquidGlass = ThemeService().liquidGlassEnabled;

    final content = Padding(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusBadge(exam.status),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.access_time,
            context.l10n.timeLabel,
            exam.timeString,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on_outlined,
            context.l10n.locationLabel,
            exam.location,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.category_outlined,
            context.l10n.typeLabel,
            localizedExamType(context, exam.type),
          ),
          if (isTodayExam) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.statusColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.examTodayCheckTheTimeCarefully,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.statusColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isLiquidGlass) {
      final theme = Theme.of(context);
      final brightness = MediaQuery.platformBrightnessOf(context);
      final isDark = brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: () => _showExamDetails(exam),
          child: LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings(
              refractiveIndex: 1.21,
              thickness: 30,
              blur: 8,
              saturation: 1.5,
              lightIntensity: isDark ? .7 : 1,
              ambientStrength: isDark ? .2 : .5,
              lightAngle: math.pi / 4,
              glassColor: isTodayExam
                  ? context.statusColors.warningContainer.withValues(alpha: 0.5)
                  : theme.colorScheme.surface.withValues(alpha: 0.6),
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: 36),
            child: Material(color: Colors.transparent, child: content),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: isTodayExam ? context.statusColors.warningContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isTodayExam
              ? BorderSide(color: context.statusColors.warning)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _showExamDetails(exam),
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return AppStatusBadge(
      label: localizedExamStatus(context, status),
      kind: isFinishedExamStatus(status)
          ? AppStatusKind.neutral
          : AppStatusKind.info,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          ': ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
