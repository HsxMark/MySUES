import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:mysues/widgets/material_you.dart';

void main() {
  testWidgets('status badge and notice use semantic themed surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(null),
        home: const Scaffold(
          body: Column(
            children: [
              AppStatusBadge(label: '已同步', kind: AppStatusKind.success),
              AppNoticeBanner(message: '请检查考试时间', kind: AppNoticeKind.warning),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AppStatusBadge), findsOneWidget);
    expect(find.byType(AppNoticeBanner), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('card section inserts dividers between settings rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(null),
        home: const Scaffold(
          body: AppCardSection(
            children: [
              ListTile(title: Text('A')),
              ListTile(title: Text('B')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('experimental appearance copy is translated to English', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light(null),
        home: const Scaffold(
          body: Column(
            children: [
              AppSectionHeader('实验性外观'),
              AppNoticeBanner(
                message:
                    '实验性外观可能降低部分页面的对比度或性能，默认 Material You 外观不受影响。',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Experimental Appearance'), findsOneWidget);
    expect(
      find.text(
        'Experimental appearance may reduce contrast or performance on some screens. The default Material You appearance is unaffected.',
      ),
      findsOneWidget,
    );
  });
}
