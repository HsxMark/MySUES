import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/l10n/exam_text.dart';
import 'package:mysues/l10n/localized_formatters.dart';

void main() {
  test('recognizes finished exam status independent of source language', () {
    expect(isFinishedExamStatus('已结束'), isTrue);
    expect(isFinishedExamStatus('Finished'), isTrue);
    expect(isFinishedExamStatus(' Ended '), isTrue);
    expect(isFinishedExamStatus('COMPLETED'), isTrue);
    expect(isFinishedExamStatus('未开始'), isFalse);
  });

  testWidgets('localizes normalized exam metadata to English', (tester) async {
    late String status;
    late String type;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            status = localizedExamStatus(context, '已结束');
            type = localizedExamType(context, '期末');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(status, 'Finished');
    expect(type, 'Final');
  });

  testWidgets('leaves unknown academic metadata unchanged', (tester) async {
    late String status;
    late String type;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            status = localizedExamStatus(context, '待学校确认');
            type = localizedExamType(context, '实践考核');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(status, '待学校确认');
    expect(type, '实践考核');
  });

  testWidgets('normalizes historical default schedule names only', (
    tester,
  ) async {
    late String chineseDefault;
    late String englishDefault;
    late String customName;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            chineseDefault = localizedScheduleName(context, '默认课表');
            englishDefault = localizedScheduleName(context, 'Default Schedule');
            customName = localizedScheduleName(context, '高数课表');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(chineseDefault, 'Default Schedule');
    expect(englishDefault, 'Default Schedule');
    expect(customName, '高数课表');
  });
}
