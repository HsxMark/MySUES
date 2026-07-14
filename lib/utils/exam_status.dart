bool isFinishedExamStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == '已结束' ||
      normalized == 'finished' ||
      normalized == 'ended' ||
      normalized == 'completed';
}
