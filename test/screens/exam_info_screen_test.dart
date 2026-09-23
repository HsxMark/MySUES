import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/exam.dart';
import 'package:mysues/screens/exam_info_screen.dart';
import 'package:mysues/services/exam_service.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Exam _upcomingExam = Exam(
  courseName: '数据结构',
  timeString: '2099-01-01 09:00-11:00',
  location: 'A101',
  type: '期末',
  status: '未开始',
);

Widget _examApp({Key? key}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ExamInfoScreen(key: key),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('banner states exam data must be imported manually', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_examApp());
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

  testWidgets('refreshes immediately when exams are saved elsewhere', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_examApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('数据结构'), findsNothing);

    // Simulates an import finishing on another tab (e.g. the schedule page's
    // one-tap extraction), which writes through ExamService.
    await ExamService.saveExams([_upcomingExam]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('数据结构'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh() reloads the cached page on demand', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_examApp(key: ExamInfoScreen.screenKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('数据结构'), findsNothing);

    // Written straight to storage so the update notifier stays untouched: this
    // covers the fallback path used when the cached exam tab becomes visible.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'exam_info_list',
      jsonEncode([_upcomingExam.toJson()]),
    );

    await ExamInfoScreen.screenKey.currentState?.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('数据结构'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
