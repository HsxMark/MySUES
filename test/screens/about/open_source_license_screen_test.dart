import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/about/open_source_license_screen.dart';
import 'package:mysues/theme/app_theme.dart';

void main() {
  for (final (name, theme) in <(String, ThemeData)>[
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('renders project information in $name theme', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OpenSourceLicenseScreen(),
        ),
      );

      expect(find.text('Open Source'), findsOneWidget);
      expect(find.text('MySUES'), findsOneWidget);
      expect(find.text('GPL-3.0'), findsOneWidget);
      expect(find.text('github.com/HsxMark/MySUES'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
