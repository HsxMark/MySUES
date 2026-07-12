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
}
