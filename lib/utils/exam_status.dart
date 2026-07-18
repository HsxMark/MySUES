bool isFinishedExamStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == '已结束' ||
      normalized == 'finished' ||
      normalized == 'ended' ||
      normalized == 'completed';
}

String examStatusForEndTime(DateTime endTime, {DateTime? now}) {
  final referenceTime = now ?? DateTime.now();
  return endTime.isAfter(referenceTime) ? '未结束' : '已结束';
}

DateTime? parseExamEndTime(String timeString) {
  final normalized = timeString.trim();
  if (normalized.isEmpty) return null;

  final compactRangeMatch = RegExp(
    r'^(\d{4}-\d{2}-\d{2})\s+\d{1,2}:\d{2}\s*-\s*(\d{1,2}:\d{2})$',
  ).firstMatch(normalized);
  if (compactRangeMatch != null) {
    return _parseExamDateTime(
      '${compactRangeMatch.group(1)} ${compactRangeMatch.group(2)}',
    );
  }

  final rangeSeparator = normalized.contains('~')
      ? '~'
      : normalized.contains(' - ')
      ? ' - '
      : null;

  if (rangeSeparator != null) {
    final parts = normalized.split(rangeSeparator);
    if (parts.length == 2) {
      final start = _parseExamDateTime(parts[0].trim());
      final endPart = parts[1].trim();
      final explicitEnd = _parseExamDateTime(endPart);
      if (explicitEnd != null) return explicitEnd;

      if (start != null && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(endPart)) {
        final timeParts = endPart.split(':');
        return DateTime(
          start.year,
          start.month,
          start.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }
    }
  }

  return _parseExamDateTime(normalized);
}

DateTime? _parseExamDateTime(String value) {
  final normalized = value.trim().replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}
