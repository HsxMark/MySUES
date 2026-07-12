import 'package:flutter/widgets.dart';

import 'legacy_text.dart';

bool isFinishedExamStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == '已结束' ||
      normalized == 'finished' ||
      normalized == 'ended' ||
      normalized == 'completed';
}

String localizedExamStatus(BuildContext context, String status) {
  final normalized = status.trim().toLowerCase();
  final source = switch (normalized) {
    'finished' || 'ended' || 'completed' => '已结束',
    'in progress' || 'ongoing' => '进行中',
    'not started' || 'upcoming' => '未开始',
    _ => status.trim(),
  };
  return legacyTranslate(context, source);
}

String localizedExamType(BuildContext context, String type) {
  final normalized = type.trim().toLowerCase();
  final source = switch (normalized) {
    'midterm' || 'mid-term' => '期中',
    'final' || 'final exam' => '期末',
    'make-up exam' || 'makeup exam' || 'resit' => '补考',
    'exam' => '考试',
    _ => type.trim(),
  };
  return legacyTranslate(context, source);
}
