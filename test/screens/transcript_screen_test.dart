import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/score.dart';
import 'package:mysues/screens/transcript_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'transcript preserves two-decimal credits and shows three-decimal GPA',
    (tester) async {
      final scores = [
        Score(
          courseName: 'Quarter credit',
          credit: 0.25,
          gradePoint: 4,
          semester: '2025-1',
        ),
        Score(
          courseName: 'Two credits',
          credit: 2,
          gradePoint: 3.7,
          semester: '2025-1',
        ),
        Score(
          courseName: 'Pending',
          credit: 0.75,
          gradePoint: 4,
          semester: '2025-1',
          isEvaluated: false,
        ),
      ];
      SharedPreferences.setMockInitialValues({
        'student_scores': jsonEncode(
          scores.map((score) => score.toJson()).toList(),
        ),
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TranscriptScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3.733'), findsNWidgets(2));
      expect(find.text('2.25'), findsOneWidget);
      expect(find.text('Credits: 0.25'), findsOneWidget);
      expect(find.text('Credits: 2.00'), findsOneWidget);
      expect(find.text('1 pending course · excluded from GPA'), findsOneWidget);
    },
  );
}
