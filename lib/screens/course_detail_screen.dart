import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

import '../models/course_detail.dart';
import '../services/theme_service.dart';
import '../utils/course_credit_formatter.dart';

class CourseDetailScreen extends StatelessWidget {
  final CourseDetail course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final unknown = context.l10n.unknown;
    final period = course.periodInfo;
    final details = <_DetailValue>[
      _DetailValue(
        context.l10n.courseName,
        _textOrUnknown(course.courseName, unknown),
      ),
      _DetailValue(
        context.l10n.courseCode,
        _textOrUnknown(course.courseCode, unknown),
      ),
      _DetailValue(
        context.l10n.courseType,
        _textOrUnknown(course.courseType, unknown),
      ),
      _DetailValue(
        context.l10n.assessmentMethod,
        _textOrUnknown(course.examMode, unknown),
      ),
      _DetailValue(
        context.l10n.offeringDepartment,
        _textOrUnknown(course.openDepartment, unknown),
      ),
      _DetailValue(
        context.l10n.teachingFormat,
        _textOrUnknown(course.teachingFormat, unknown),
      ),
      _DetailValue(context.l10n.credits, formatCourseCredits(course.credits)),
      _DetailValue(
        context.l10n.totalClassHours,
        period.total == null ? unknown : formatCourseNumber(period.total!),
      ),
      _DetailValue(
        context.l10n.teachingWeeks,
        period.weeks?.toString() ?? unknown,
      ),
    ];
    final components = _positivePeriodComponents(context, period);

    return Scaffold(
      appBar: AppBar(
        title: Text(_textOrUnknown(course.courseName, unknown)),
        backgroundColor: ThemeService().liquidGlassEnabled
            ? Colors.transparent
            : null,
        elevation: ThemeService().liquidGlassEnabled ? 0 : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  for (var index = 0; index < details.length; index++) ...[
                    _DetailRow(detail: details[index]),
                    if (index != details.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
          if (components.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                context.l10n.classHourBreakdown,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < components.length; index++) ...[
                      _DetailRow(detail: components[index]),
                      if (index != components.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_DetailValue> _positivePeriodComponents(
    BuildContext context,
    CoursePeriodInfo period,
  ) {
    final values = <_DetailValue>[];

    void add(String label, double? value) {
      if (value != null && value > 0) {
        values.add(_DetailValue(label, formatCourseNumber(value)));
      }
    }

    add(context.l10n.theoryHours, period.theory);
    add(context.l10n.practiceHours, period.practice);
    add(context.l10n.focusedPracticeHours, period.focusPractice);
    add(context.l10n.dispersedPracticeHours, period.dispersedPractice);
    add(context.l10n.assessmentHours, period.test);
    add(context.l10n.experimentHours, period.experiment);
    add(context.l10n.computerHours, period.machine);
    add(context.l10n.designHours, period.design);
    add(context.l10n.extracurricularHours, period.extra);
    return values;
  }

  String _textOrUnknown(String value, String unknown) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? unknown : trimmed;
  }
}

class _DetailRow extends StatelessWidget {
  final _DetailValue detail;

  const _DetailRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              detail.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              detail.value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailValue {
  final String label;
  final String value;

  const _DetailValue(this.label, this.value);
}
