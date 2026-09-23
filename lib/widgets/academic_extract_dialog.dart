import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

import '../models/academic_extract.dart';

/// Checklist style progress dialog used by the one-tap academic extraction.
///
/// The dialog is stateless: the orchestrating screen owns a
/// [ValueListenable] of [ExtractDialogState] and pushes new snapshots while
/// the individual extraction steps run.
class AcademicExtractDialog extends StatelessWidget {
  const AcademicExtractDialog({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onRetryFailed,
    required this.onDone,
  });

  final ValueListenable<ExtractDialogState> state;
  final VoidCallback onCancel;
  final VoidCallback onRetryFailed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExtractDialogState>(
      valueListenable: state,
      builder: (context, value, _) {
        final l10n = context.l10n;
        final summary = value.summary;
        return PopScope(
          // While a run is in flight the dialog must stay on screen; once the
          // summary is shown, backing out is the same as tapping "done".
          canPop: value.finished,
          child: AlertDialog(
            title: Text(
              value.finished ? l10n.extractSummaryTitle : l10n.oneTapExtract,
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: _progress(value)),
                    ),
                    if (value.statusText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        value.statusText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...value.progress.map((item) => _buildRow(context, item)),
                    if (value.finished) ...[
                      const Divider(height: 24),
                      Text(
                        l10n.extractSummaryCounts(
                          summary.successCount,
                          summary.failedTotal,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (value.conflictCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.extractConflictSummary(value.conflictCount),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: value.finished
                ? [
                    if (summary.hasFailures)
                      TextButton(
                        onPressed: onRetryFailed,
                        child: Text(l10n.extractRetryFailed),
                      ),
                    FilledButton(onPressed: onDone, child: Text(l10n.done)),
                  ]
                : [
                    TextButton(
                      onPressed: value.cancelling ? null : onCancel,
                      child: Text(l10n.cancel),
                    ),
                  ],
          ),
        );
      },
    );
  }

  double _progress(ExtractDialogState value) {
    final total = value.progress.length;
    if (total == 0) return 0;
    final done = value.progress.where((item) => item.isTerminal).length;
    return done / total;
  }

  Widget _buildRow(BuildContext context, ExtractTaskProgress item) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final leading = switch (item.status) {
      ExtractTaskStatus.pending => Icon(
        Icons.radio_button_unchecked,
        size: 20,
        color: scheme.outline,
      ),
      ExtractTaskStatus.running => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      ),
      ExtractTaskStatus.success => Icon(
        Icons.check_circle,
        size: 20,
        color: scheme.primary,
      ),
      ExtractTaskStatus.failure => Icon(
        Icons.error_outline,
        size: 20,
        color: scheme.error,
      ),
      ExtractTaskStatus.cancelled => Icon(
        Icons.cancel_outlined,
        size: 20,
        color: scheme.outline,
      ),
    };

    final (subtitle, subtitleColor) = switch (item.status) {
      ExtractTaskStatus.pending => (
        l10n.extractStatusPending,
        scheme.onSurfaceVariant,
      ),
      ExtractTaskStatus.running => (l10n.extractStatusRunning, scheme.primary),
      ExtractTaskStatus.success => (
        item.detail ?? l10n.extractStatusSuccess,
        scheme.onSurfaceVariant,
      ),
      ExtractTaskStatus.failure => (
        item.detail ?? l10n.extractStatusFailed,
        scheme.error,
      ),
      ExtractTaskStatus.cancelled => (
        item.detail ?? l10n.extractStatusCancelled,
        scheme.onSurfaceVariant,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: leading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _taskLabel(context, item.task),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _taskLabel(BuildContext context, ExtractTask task) {
    final l10n = context.l10n;
    return switch (task) {
      ExtractTask.schedule => l10n.extractTaskSchedule,
      ExtractTask.scores => l10n.extractTaskScores,
      ExtractTask.profile => l10n.extractTaskProfile,
      ExtractTask.exams => l10n.extractTaskExams,
    };
  }
}
