String formatTotalCredits(num value) =>
    _formatTruncated(value, keepZeros: true);

String formatCourseCredits(num value) =>
    _formatTruncated(value, keepZeros: false);

String formatCourseNumber(num value) =>
    _formatTruncated(value, keepZeros: false);

String _formatTruncated(num value, {required bool keepZeros}) {
  final numericValue = value.toDouble();
  if (!numericValue.isFinite || numericValue <= 0) {
    return keepZeros ? '0.00' : '0';
  }

  final scaled = (numericValue * 100 + 1e-9).truncate();
  final formatted = (scaled / 100).toStringAsFixed(2);
  if (keepZeros) return formatted;
  return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
}
