import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/add_course_screen.dart';
import 'package:mysues/screens/add_exam_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('add course form is fully localized in English', (tester) async {
    await tester.pumpWidget(_localizedApp(const AddCourseScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add Course'), findsOneWidget);
    expect(find.text('Course Name'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Class Time'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter Course Name'), findsOneWidget);
  });

  testWidgets('add exam defaults and validation are localized in English', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const AddExamScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add Exam'), findsOneWidget);
    expect(find.text('Course Name'), findsOneWidget);
    expect(find.text('Final'), findsWidgets);

    await tester.ensureVisible(find.text('Save Exam'));
    await tester.tap(find.text('Save Exam'));
    await tester.pump();

    expect(find.text('Enter a course name'), findsOneWidget);
  });
}

Widget _localizedApp(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
