import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/about/author_screen.dart';
import 'package:mysues/theme/app_theme.dart';

void main() {
  for (final (name, theme) in <(String, ThemeData)>[
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('renders author information in $name theme', (tester) async {
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
          home: const AuthorScreen(),
        ),
      );

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('HsxMark'), findsNothing);
      expect(find.text('Independent Developer'), findsNothing);
      expect(find.text('github.com/HsxMark'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(
        (avatar.backgroundImage! as AssetImage).assetName,
        'assets/images/author_avatar.png',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders localized author information in Chinese', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AuthorScreen(),
      ),
    );

    expect(find.text('作者'), findsOneWidget);
    expect(find.text('独立开发者'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bundles the author avatar locally', (tester) async {
    final data = await rootBundle.load('assets/images/author_avatar.png');

    expect(data.lengthInBytes, greaterThan(0));
  });
}
