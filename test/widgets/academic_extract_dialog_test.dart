import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/academic_extract.dart';
import 'package:mysues/widgets/academic_extract_dialog.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// A page with a dialog on top, mirroring the navigator shape the extraction
/// flow uses (WebView page → extraction dialog).
class _DialogHarness {
  _DialogHarness(this.popped);

  final Completer<void> popped;
  late BuildContext dialogContext;

  NavigatorState get navigator => Navigator.of(dialogContext);
}

Future<_DialogHarness> _pumpPageWithDialog(WidgetTester tester) async {
  final harness = _DialogHarness(Completer<void>());

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    harness.dialogContext = ctx;
                    return const AlertDialog(title: Text('extract-dialog'));
                  },
                ).whenComplete(harness.popped.complete);
              },
              child: const Text('host-page'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('host-page'));
  await tester.pumpAndSettle();
  expect(find.text('extract-dialog'), findsOneWidget);

  return harness;
}

void main() {
  testWidgets('lists every task in the canonical order while running', (
    tester,
  ) async {
    final state = ValueNotifier<ExtractDialogState>(
      const ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.running,
          ),
          ExtractTaskProgress(task: ExtractTask.scores),
          ExtractTaskProgress(task: ExtractTask.profile),
          ExtractTaskProgress(task: ExtractTask.exams),
        ],
        statusText: '正在连接教务系统…',
      ),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _wrap(
        AcademicExtractDialog(
          state: state,
          onCancel: () {},
          onRetryFailed: () {},
          onDone: () {},
          onShowConflictDetails: () {},
        ),
      ),
    );

    expect(find.text('课表'), findsOneWidget);
    expect(find.text('成绩'), findsOneWidget);
    expect(find.text('个人信息'), findsOneWidget);
    expect(find.text('考试信息'), findsOneWidget);
    expect(find.text('正在连接教务系统…'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('完成'), findsNothing);
    expect(find.text('重试失败项'), findsNothing);

    final progressBar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progressBar.value, 0);
  });

  testWidgets('shows the summary, retry and conflict notice when finished', (
    tester,
  ) async {
    final state = ValueNotifier<ExtractDialogState>(
      const ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.success,
            detail: '32 条课程记录',
          ),
          ExtractTaskProgress(
            task: ExtractTask.scores,
            status: ExtractTaskStatus.failure,
            detail: '未获取到成绩',
          ),
          ExtractTaskProgress(
            task: ExtractTask.profile,
            status: ExtractTaskStatus.success,
          ),
          ExtractTaskProgress(
            task: ExtractTask.exams,
            status: ExtractTaskStatus.success,
          ),
        ],
        finished: true,
        conflictDetails: ['• 高等数学 (周三 第 3 - 4 节 )', '• 大学物理 (周五 第 5 - 6 节 )'],
      ),
    );
    addTearDown(state.dispose);

    var detailsRequested = 0;
    await tester.pumpWidget(
      _wrap(
        AcademicExtractDialog(
          state: state,
          onCancel: () {},
          onRetryFailed: () {},
          onDone: () {},
          onShowConflictDetails: () => detailsRequested++,
        ),
      ),
    );

    expect(find.text('提取结果'), findsOneWidget);
    expect(find.text('成功 3 项 · 失败 1 项'), findsOneWidget);
    expect(find.text('未获取到成绩'), findsOneWidget);
    expect(find.text('32 条课程记录'), findsOneWidget);
    expect(find.text('发现 2 处课程时间冲突，可稍后在课表中处理'), findsOneWidget);
    expect(find.text('查看冲突详情'), findsOneWidget);
    expect(find.text('重试失败项'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('取消'), findsNothing);

    await tester.tap(find.text('查看冲突详情'));
    await tester.pump();
    expect(detailsRequested, 1);

    final progressBar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progressBar.value, 1);
  });

  testWidgets('hides the retry button when every task succeeded', (
    tester,
  ) async {
    final state = ValueNotifier<ExtractDialogState>(
      const ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.profile,
            status: ExtractTaskStatus.success,
          ),
        ],
        finished: true,
      ),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _wrap(
        AcademicExtractDialog(
          state: state,
          onCancel: () {},
          onRetryFailed: () {},
          onDone: () {},
          onShowConflictDetails: () {},
        ),
      ),
    );

    expect(find.text('重试失败项'), findsNothing);
    expect(find.text('查看冲突详情'), findsNothing);
    expect(find.text('完成'), findsOneWidget);
  });

  testWidgets('disables the cancel button while cancelling', (tester) async {
    final state = ValueNotifier<ExtractDialogState>(
      const ExtractDialogState(
        progress: [
          ExtractTaskProgress(
            task: ExtractTask.schedule,
            status: ExtractTaskStatus.running,
          ),
          ExtractTaskProgress(task: ExtractTask.scores),
        ],
        cancelling: true,
        statusText: '正在取消…',
      ),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _wrap(
        AcademicExtractDialog(
          state: state,
          onCancel: () {},
          onRetryFailed: () {},
          onDone: () {},
          onShowConflictDetails: () {},
        ),
      ),
    );

    expect(find.text('正在取消…'), findsOneWidget);
    final cancelButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '取消'),
    );
    expect(cancelButton.onPressed, isNull);
  });

  group('ExtractDialogGuard', () {
    test('stays open until the dialog route future completes', () async {
      final completer = Completer<void>();
      final guard = ExtractDialogGuard(completer.future);

      expect(guard.isOpen, isTrue);

      completer.complete();
      // `whenComplete` runs as a microtask, so the flag flips after a yield.
      await Future<void>.delayed(Duration.zero);

      expect(guard.isOpen, isFalse);
    });
  });

  testWidgets('a guarded pop keeps the page below the dialog', (tester) async {
    final harness = await _pumpPageWithDialog(tester);
    final guard = ExtractDialogGuard(harness.popped.future);

    // The back gesture pops the dialog route: its future resolves while the
    // dialog widget is still mounted for the exit animation, and the dialog
    // route is no longer "present", so a second pop would hit the host page.
    harness.navigator.pop();
    await tester.pump();

    expect(guard.isOpen, isFalse);
    expect(harness.dialogContext.mounted, isTrue);

    // This is the check the extraction flow makes before popping.
    if (guard.isOpen && harness.dialogContext.mounted) {
      harness.navigator.pop();
    }

    await tester.pumpAndSettle();

    expect(find.text('host-page'), findsOneWidget);
    expect(find.text('extract-dialog'), findsNothing);
  });

  testWidgets('without the guard the second pop takes the page below', (
    tester,
  ) async {
    final harness = await _pumpPageWithDialog(tester);

    harness.navigator.pop();
    await tester.pump();
    // The unguarded second pop that the guard exists to prevent.
    harness.navigator.pop();

    await tester.pumpAndSettle();

    expect(find.text('host-page'), findsNothing);
  });
}
