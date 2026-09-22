import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/academic_extract.dart';

void main() {
  group('ExtractTaskProgress', () {
    test('only finished states are terminal', () {
      for (final status in ExtractTaskStatus.values) {
        final progress = ExtractTaskProgress(
          task: ExtractTask.scores,
          status: status,
        );
        final expected =
            status == ExtractTaskStatus.success ||
            status == ExtractTaskStatus.failure ||
            status == ExtractTaskStatus.cancelled;
        expect(progress.isTerminal, expected, reason: status.name);
      }
    });

    test('copyWith can clear a previous error detail', () {
      const progress = ExtractTaskProgress(
        task: ExtractTask.schedule,
        status: ExtractTaskStatus.failure,
        detail: 'boom',
      );

      final retried = progress.copyWith(
        status: ExtractTaskStatus.pending,
        clearDetail: true,
      );

      expect(retried.status, ExtractTaskStatus.pending);
      expect(retried.detail, isNull);
    });
  });

  group('ExtractSummary', () {
    test('counts successes, failures, cancellations and conflicts', () {
      final summary = ExtractSummary.fromProgress(
        const [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.success,
          ),
          ExtractTaskProgress(
            task: ExtractTask.scores,
            status: ExtractTaskStatus.failure,
          ),
          ExtractTaskProgress(
            task: ExtractTask.profile,
            status: ExtractTaskStatus.cancelled,
          ),
          ExtractTaskProgress(task: ExtractTask.exams),
        ],
        conflictCount: 2,
      );

      expect(summary.successCount, 1);
      expect(summary.failureCount, 1);
      expect(summary.cancelledCount, 1);
      expect(summary.failedTotal, 2);
      expect(summary.totalCount, 3);
      expect(summary.conflictCount, 2);
      expect(summary.hasFailures, isTrue);
    });

    test('reports no failures when every task succeeded', () {
      final summary = ExtractSummary.fromProgress(
        const [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.success,
          ),
          ExtractTaskProgress(
            task: ExtractTask.exams,
            status: ExtractTaskStatus.success,
          ),
        ],
      );

      expect(summary.hasFailures, isFalse);
      expect(summary.failedTotal, 0);
      expect(summary.totalCount, 2);
    });
  });

  group('ExtractDialogState', () {
    test('exposes the summary of its progress list', () {
      const state = ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.profile,
            status: ExtractTaskStatus.success,
          ),
        ],
        conflictCount: 3,
      );

      expect(state.summary.successCount, 1);
      expect(state.summary.conflictCount, 3);
    });
  });
}
