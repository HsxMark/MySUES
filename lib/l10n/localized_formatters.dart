import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';
import 'l10n.dart';

String localizedWeekdayShort(AppLocalizations l10n, int weekday) =>
    switch (weekday) {
      DateTime.monday => l10n.mondayShort,
      DateTime.tuesday => l10n.tuesdayShort,
      DateTime.wednesday => l10n.wednesdayShort,
      DateTime.thursday => l10n.thursdayShort,
      DateTime.friday => l10n.fridayShort,
      DateTime.saturday => l10n.saturdayShort,
      _ => l10n.sundayShort,
    };

String localizedWeekdayLabel(AppLocalizations l10n, int weekday) =>
    switch (weekday) {
      DateTime.monday => l10n.mon,
      DateTime.tuesday => l10n.tue,
      DateTime.wednesday => l10n.wed,
      DateTime.thursday => l10n.thu,
      DateTime.friday => l10n.fri,
      DateTime.saturday => l10n.sat,
      _ => l10n.sun,
    };

String localizedScheduleName(BuildContext context, String name) {
  if (name == '默认课表' || name == 'Default Schedule') {
    return context.l10n.defaultSchedule;
  }
  return name;
}

String localizedMonthTitle(BuildContext context, DateTime date) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return '${date.month}月';
  }
  return DateFormat.MMMM(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(date);
}

String localizedCompactMonth(BuildContext context, DateTime date) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return '${date.month}\n月';
  }
  return DateFormat.MMM(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(date);
}

String localizedScheduleEventDate(
  BuildContext context,
  DateTime date,
  String startTime,
  String endTime,
) => context.l10n.scheduleEventDate(
  date.month,
  date.day,
  localizedWeekdayLabel(context.l10n, date.weekday),
  startTime,
  endTime,
);

String localizedSemesterPosition(
  BuildContext context,
  String semester,
  int week,
  DateTime date,
) => context.l10n.semesterWeekPosition(
  semester,
  week,
  localizedWeekdayLabel(context.l10n, date.weekday),
);

String localizedExamStatus(BuildContext context, String status) {
  final normalized = status.trim().toLowerCase();
  return switch (normalized) {
    '已结束' || 'finished' || 'ended' || 'completed' => context.l10n.finished,
    '进行中' || 'in progress' || 'ongoing' => context.l10n.inProgress,
    '未开始' || '未结束' || 'not started' || 'upcoming' => context.l10n.notStarted,
    _ => status.trim(),
  };
}

String localizedExamType(BuildContext context, String type) {
  final normalized = type.trim().toLowerCase();
  return switch (normalized) {
    '期中' || 'midterm' || 'mid-term' => context.l10n.midterm,
    '期末' || 'final' || 'final exam' => context.l10n.finalExam,
    '补考' ||
    'make-up exam' ||
    'makeup exam' ||
    'resit' => context.l10n.makeUpExam,
    '考试' || 'exam' => context.l10n.exams,
    _ => type.trim(),
  };
}
