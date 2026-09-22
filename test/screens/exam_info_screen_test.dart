import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/exam_info_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('banner states exam data must be imported manually', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExamInfoScreen(),
      ),
    );
    // Let ExamService.loadExams() finish and the screen rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('考试信息不会自动同步，必须手动导入后才会显示；导入内容也可能滞后，请以教务系统为准。'),
      findsOneWidget,
    );
    expect(
      find.text('考试信息非即时获取，仅供参考，请以教务系统提示为准！'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
