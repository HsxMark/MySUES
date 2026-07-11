import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/l10n/legacy_text.dart';
import 'package:mysues/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unsupported system locales fall back to English', () {
    expect(LocaleService.resolveLocale(const Locale('ja')).languageCode, 'en');
    expect(
      LocaleService.resolveLocale(const Locale('zh', 'TW')).languageCode,
      'zh',
    );
  });

  test('language choice is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocaleService();
    await service.loadSettings();
    await service.setLanguage(AppLanguage.english);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'en');
    expect(service.localeOverride, const Locale('en'));
  });

  testWidgets('generated and legacy localizations render English', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [AppLocalizations.delegate],
        home: Scaffold(
          body: Column(
            children: [
              _GeneratedText(),
              LText('课程表'),
              LText('第 3 周'),
              LText('周一 第1 - 2节 08:15-09:55'),
              LText('考试前 2 天 09:00 提醒'),
              LText('总平均绩点 (GPA)'),
              LText('修读学分'),
              LText('本学期有 2 门课程未评教，不计入GPA'),
              LText('上次导入成绩时间2026-07-12 10:30，导入方式PDF文件'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Week 3'), findsOneWidget);
    expect(find.text('Monday · Periods 1–2 08:15-09:55'), findsOneWidget);
    expect(find.text('2 days before the exam at 09:00'), findsOneWidget);
    expect(find.text('Overall GPA'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('2 pending · excluded from GPA'), findsOneWidget);
    expect(find.text('Imported 2026-07-12 10:30 · PDF File'), findsOneWidget);
  });

  testWidgets('English schedule dates contain no Chinese month suffix', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(localizedMonthTitle(context, DateTime(2026, 7, 12))),
              Text(localizedCompactMonth(context, DateTime(2026, 7, 12))),
              Text(
                localizedScheduleEventDate(
                  context,
                  DateTime(2026, 7, 12),
                  '08:15',
                  '09:55',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('July'), findsOneWidget);
    expect(find.text('Jul'), findsOneWidget);
    expect(find.textContaining('Jul 12, Sun'), findsOneWidget);
    expect(find.textContaining('月'), findsNothing);
  });
}

class _GeneratedText extends StatelessWidget {
  const _GeneratedText();

  @override
  Widget build(BuildContext context) =>
      Text(AppLocalizations.of(context).settings);
}
