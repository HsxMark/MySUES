import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

import '../models/course_detail.dart';
import '../services/schedule_service.dart';
import '../services/theme_service.dart';
import '../utils/course_credit_formatter.dart';
import '../widgets/material_you.dart';
import 'course_detail_screen.dart';

class CourseCatalogScreen extends StatefulWidget {
  final int tableId;
  final String fallbackSemesterName;

  const CourseCatalogScreen({
    super.key,
    required this.tableId,
    required this.fallbackSemesterName,
  });

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  SemesterCourseCatalog? _catalog;
  List<CourseDetail> _courses = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await ScheduleDataService.loadCourseCatalog(
      tableId: widget.tableId,
    );
    final courses = [...?catalog?.courses]
      ..sort((a, b) {
        final byName = a.courseName.compareTo(b.courseName);
        if (byName != 0) return byName;
        return a.courseCode.compareTo(b.courseCode);
      });

    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _courses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final semesterName = _catalog?.semesterName.trim().isNotEmpty == true
        ? _catalog!.semesterName
        : widget.fallbackSemesterName;
    final totalCredits = _catalog?.totalCredits ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(semesterName),
        backgroundColor: ThemeService().liquidGlassEnabled
            ? Colors.transparent
            : null,
        elevation: ThemeService().liquidGlassEnabled ? 0 : null,
      ),
      body: Column(
        children: [
          AppNoticeBanner(
            message: context.l10n.courseCatalogDisclaimer,
            kind: AppNoticeKind.warning,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: context.l10n.semesterCourseCount,
                                value: _courses.length.toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: context.l10n.semesterTotalCredits,
                                value: formatTotalCredits(totalCredits),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  title: Text(
                                    course.courseName.isEmpty
                                        ? context.l10n.unknown
                                        : course.courseName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CourseDetailScreen(course: course),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
