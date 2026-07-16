import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/schedule_table.dart';
import 'package:mysues/screens/daily_schedule_screen.dart';
import 'package:mysues/screens/schedule_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final table = ScheduleTable(
      id: 1,
      tableName: '2026-2027学年第1学期',
      startDate: '2026-09-14',
    );
    SharedPreferences.setMockInitialValues({
      'schedule_tables': jsonEncode([table.toJson()]),
      'current_table_id': 1,
      'schedule_courses': '[]',
      'time_details': '[]',
    });
  });

  testWidgets('weekly schedule shows the course catalog action', (tester) async {
    await tester.pumpWidget(_app(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
  });

  testWidgets('daily schedule shows the course catalog action', (tester) async {
    await tester.pumpWidget(_app(const DailyScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
  });
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
