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
        ),
      ),
    );

    expect(find.text('最新课表'), findsOneWidget);
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
        conflictCount: 2,
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
        ),
      ),
    );

    expect(find.text('提取结果'), findsOneWidget);
    expect(find.text('成功 3 项 · 失败 1 项'), findsOneWidget);
    expect(find.text('未获取到成绩'), findsOneWidget);
    expect(find.text('32 条课程记录'), findsOneWidget);
    expect(find.text('发现 2 处课程时间冲突，可稍后在课表中处理'), findsOneWidget);
    expect(find.text('重试失败项'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('取消'), findsNothing);

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
        ),
      ),
    );

    expect(find.text('重试失败项'), findsNothing);
    expect(find.text('完成'), findsOneWidget);
  });
}
