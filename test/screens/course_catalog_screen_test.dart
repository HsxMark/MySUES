import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/course_detail.dart';
import 'package:mysues/screens/course_catalog_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('catalog shows summary, sorted compact list, and detail fields', (
    tester,
  ) async {
    final catalog = SemesterCourseCatalog(
      tableId: 3,
      semesterName: '2026-2027学年第1学期',
      totalCredits: 6.25,
      courses: const [
        CourseDetail(
          sourceKey: 'lesson:2',
          courseName: '网络流媒体',
          courseCode: '021553',
          courseType: '专业选修课',
          examMode: '',
          openDepartment: '电子电气工程学院',
          teachingFormat: '理论课、实践课',
          credits: 2,
          periodInfo: CoursePeriodInfo(
            total: 32,
            weeks: 8,
            theory: 20,
            practice: 12,
          ),
        ),
        CourseDetail(
          sourceKey: 'lesson:1',
          courseName: '专业综合设计',
          courseCode: '020612',
          courseType: '集中实践教学环节',
          examMode: '考查',
          openDepartment: '电子电气工程学院',
          teachingFormat: '理论课、实验课',
          credits: 2,
          periodInfo: CoursePeriodInfo(
            total: 60,
            weeks: 2,
            theory: 0,
            experiment: 60,
          ),
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'semester_course_catalogs': jsonEncode([catalog.toJson()]),
    });

    await tester.pumpWidget(
      _app(
        const CourseCatalogScreen(tableId: 3, fallbackSemesterName: 'Fallback'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-2027学年第1学期'), findsOneWidget);
    expect(find.text('Semester Courses'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Semester Credits'), findsOneWidget);
    expect(find.text('6.25'), findsOneWidget);
    expect(find.text('2 credits'), findsNWidgets(2));

    final designTop = tester.getTopLeft(find.text('专业综合设计')).dy;
    final streamingTop = tester.getTopLeft(find.text('网络流媒体')).dy;
    expect(designTop, lessThan(streamingTop));

    await tester.tap(find.text('专业综合设计'));
    await tester.pumpAndSettle();

    expect(find.text('Course Code'), findsOneWidget);
    expect(find.text('020612'), findsOneWidget);
    expect(find.text('Assessment Method'), findsOneWidget);
    expect(find.text('考查'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Class Hour Breakdown'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Class Hour Breakdown'), findsOneWidget);
    expect(find.text('Experiment'), findsOneWidget);
    expect(find.text('60'), findsNWidgets(2));
    expect(find.text('Theory'), findsNothing);
  });

  testWidgets(
    'catalog without saved details keeps zero summary and empty list',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const CourseCatalogScreen(
            tableId: 99,
            fallbackSemesterName: 'Manual Schedule',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual Schedule'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    },
  );
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: AppTheme.light(null),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
