import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/profile_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _profileApp({Locale locale = const Locale('zh')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ProfileScreen(),
  );
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(_profileApp(locale: locale));
  // Let ProfileScreen._loadData() and the schedule lookup finish.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a sync button instead of a sync status badge', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpProfile(tester);

    expect(find.widgetWithText(FilledButton, '去同步'), findsOneWidget);
    expect(find.text('已同步'), findsNothing);
    expect(find.text('未同步'), findsNothing);
    expect(find.text('点击开始同步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the button label fixed once synced', (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_sync_time_academic': '2026-09-22 12:00',
    });

    await _pumpProfile(tester);

    expect(find.text('2026-09-22 12:00'), findsOneWidget);
    expect(find.text('点击开始同步'), findsNothing);
    expect(find.widgetWithText(FilledButton, '去同步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync button opens the sync disclaimer', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpProfile(tester);

    final button = find.widgetWithText(FilledButton, '去同步');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('免责声明'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync card fits a narrow screen in English', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    await _pumpProfile(tester, locale: const Locale('en'));

    expect(find.widgetWithText(FilledButton, 'Start Sync'), findsOneWidget);
    expect(find.text('Academic Sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
