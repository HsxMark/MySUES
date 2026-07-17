import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/about/open_source_license_screen.dart';
import 'package:mysues/screens/settings/display_settings_screen.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('display settings no longer exposes font selection', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const DisplaySettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Display'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Font'), findsNothing);
    expect(find.text('Font Style'), findsNothing);
    expect(find.text('System Default'), findsNothing);
  });

  testWidgets('open-source screen no longer lists bundled fonts', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const OpenSourceLicenseScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Project Information'), findsOneWidget);
    expect(find.text('Font Resources'), findsNothing);
  });
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light(),
  home: home,
);
