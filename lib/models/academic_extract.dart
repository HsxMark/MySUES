/// Task kinds available in the academic extraction flow.
///
/// The declaration order is the order used by the one-tap extraction flow,
/// regardless of the order the user ticked the checkboxes in.
enum ExtractTask { schedule, scores, profile, exams }

/// Lifecycle of a single extraction task inside the progress dialog.
enum ExtractTaskStatus { pending, running, success, failure, cancelled }

/// Immutable progress snapshot for one checklist row.
class ExtractTaskProgress {
  const ExtractTaskProgress({
    required this.task,
    this.status = ExtractTaskStatus.pending,
    this.detail,
  });

  final ExtractTask task;
  final ExtractTaskStatus status;

  /// Human readable detail: record counts on success, error message on failure.
  final String? detail;

  bool get isTerminal =>
      status == ExtractTaskStatus.success ||
      status == ExtractTaskStatus.failure ||
      status == ExtractTaskStatus.cancelled;

  ExtractTaskProgress copyWith({
    ExtractTaskStatus? status,
    String? detail,
    bool clearDetail = false,
  }) {
    return ExtractTaskProgress(
      task: task,
      status: status ?? this.status,
      detail: clearDetail ? null : (detail ?? this.detail),
    );
  }
}

/// Aggregated result shown at the bottom of the extraction dialog.
class ExtractSummary {
  const ExtractSummary({
    required this.successCount,
    required this.failureCount,
    required this.cancelledCount,
    this.conflictCount = 0,
  });

  factory ExtractSummary.fromProgress(
    List<ExtractTaskProgress> progress, {
    int conflictCount = 0,
  }) {
    var success = 0;
    var failure = 0;
    var cancelled = 0;
    for (final item in progress) {
      if (item.status == ExtractTaskStatus.success) {
        success++;
      } else if (item.status == ExtractTaskStatus.failure) {
        failure++;
      } else if (item.status == ExtractTaskStatus.cancelled) {
        cancelled++;
      }
    }
    return ExtractSummary(
      successCount: success,
      failureCount: failure,
      cancelledCount: cancelled,
      conflictCount: conflictCount,
    );
  }

  final int successCount;
  final int failureCount;
  final int cancelledCount;
  final int conflictCount;

  /// How many rows can be retried: failed plus cancelled ones.
  int get failedTotal => failureCount + cancelledCount;

  bool get hasFailures => failedTotal > 0;

  int get totalCount => successCount + failedTotal;
}

/// Everything the extraction dialog needs to render itself.
class ExtractDialogState {
  const ExtractDialogState({
    this.progress = const [],
    this.finished = false,
    this.cancelling = false,
    this.conflictCount = 0,
    this.statusText,
  });

  final List<ExtractTaskProgress> progress;
  final bool finished;

  /// True from the moment the user taps cancel until the run is rolled back.
  final bool cancelling;
  final int conflictCount;
  final String? statusText;

  ExtractSummary get summary =>
      ExtractSummary.fromProgress(progress, conflictCount: conflictCount);

  ExtractDialogState copyWith({
    List<ExtractTaskProgress>? progress,
    bool? finished,
    bool? cancelling,
    int? conflictCount,
    String? statusText,
    bool clearStatusText = false,
  }) {
    return ExtractDialogState(
      progress: progress ?? this.progress,
      finished: finished ?? this.finished,
      cancelling: cancelling ?? this.cancelling,
      conflictCount: conflictCount ?? this.conflictCount,
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
    );
  }
}
