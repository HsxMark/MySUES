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
      final summary = ExtractSummary.fromProgress(const [
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
      ], conflictCount: 2);

      expect(summary.successCount, 1);
      expect(summary.failureCount, 1);
      expect(summary.cancelledCount, 1);
      expect(summary.failedTotal, 2);
      expect(summary.conflictCount, 2);
      expect(summary.hasFailures, isTrue);
    });

    test('reports no failures when every task succeeded', () {
      final summary = ExtractSummary.fromProgress(const [
        ExtractTaskProgress(
          task: ExtractTask.schedule,
          status: ExtractTaskStatus.success,
        ),
        ExtractTaskProgress(
          task: ExtractTask.exams,
          status: ExtractTaskStatus.success,
        ),
      ]);

      expect(summary.hasFailures, isFalse);
      expect(summary.failedTotal, 0);
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
        conflictDetails: ['• 高等数学 (周三 第 3 - 4 节 )', '• 大学物理'],
      );

      expect(state.summary.successCount, 1);
      expect(state.conflictCount, 2);
      expect(state.summary.conflictCount, 2);
    });

    test('reports no conflicts when no details were recorded', () {
      const state = ExtractDialogState();
      expect(state.conflictCount, 0);
      expect(state.conflictDetails, isEmpty);
    });

    test('tracks the cancelling flag', () {
      const state = ExtractDialogState();
      expect(state.cancelling, isFalse);

      final cancelling = state.copyWith(cancelling: true, statusText: '正在取消…');
      expect(cancelling.cancelling, isTrue);
      expect(cancelling.statusText, '正在取消…');

      // copyWith keeps the flag unless it is explicitly changed.
      expect(cancelling.copyWith(finished: true).cancelling, isTrue);
    });
  });

  group('ExtractDialogState.withUnfinishedAsFailed', () {
    test('fails pending and running rows while keeping finished ones', () {
      const state = ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.success,
            detail: '32 条课程记录',
          ),
          ExtractTaskProgress(
            task: ExtractTask.scores,
            status: ExtractTaskStatus.running,
          ),
          ExtractTaskProgress(task: ExtractTask.profile),
        ],
        statusText: '正在连接教务系统…',
      );

      final failed = state.withUnfinishedAsFailed('课程表页面打不开');

      expect(failed.progress[0].status, ExtractTaskStatus.success);
      expect(failed.progress[0].detail, '32 条课程记录');
      expect(failed.progress[1].status, ExtractTaskStatus.failure);
      expect(failed.progress[1].detail, '课程表页面打不开');
      expect(failed.progress[2].status, ExtractTaskStatus.failure);
      expect(failed.progress[2].detail, '课程表页面打不开');
      expect(failed.statusText, isNull);
      expect(failed.summary.failureCount, 2);
      expect(failed.summary.successCount, 1);
      expect(failed.summary.hasFailures, isTrue);
      expect(failed.finished, isFalse);
    });

    test('leaves cancelled rows untouched', () {
      const state = ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.scores,
            status: ExtractTaskStatus.cancelled,
            detail: '已取消',
          ),
        ],
      );

      final failed = state.withUnfinishedAsFailed('boom');

      expect(failed.progress.single.status, ExtractTaskStatus.cancelled);
      expect(failed.progress.single.detail, '已取消');
    });
  });
}
