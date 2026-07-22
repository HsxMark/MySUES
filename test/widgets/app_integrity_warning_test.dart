import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/about_screen.dart';
import 'package:mysues/services/app_integrity_service.dart';
import 'package:mysues/widgets/app_integrity_warning.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppIntegrityService().resetForTesting();
  });

  tearDown(() {
    AppIntegrityService().resetForTesting();
  });

  testWidgets('startup warning can be suppressed after acknowledgement', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showAppIntegrityWarningDialog(context),
                child: const Text('显示警告'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示警告'));
    await tester.pumpAndSettle();

    expect(find.text('应用来源无法确认'), findsOneWidget);
    expect(find.textContaining('签名'), findsNothing);
    expect(find.text('前往官方网站下载'), findsOneWidget);
    expect(find.text('不再提醒'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续使用'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(hideAppIntegrityWarningPreferenceKey), isTrue);

    await tester.tap(find.text('显示警告'));
    await tester.pumpAndSettle();
    expect(find.text('应用来源无法确认'), findsNothing);
  });

  testWidgets('startup warning returns when it was not suppressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showAppIntegrityWarningDialog(context),
                child: const Text('显示警告'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示警告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续使用'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('显示警告'));
    await tester.pumpAndSettle();
    expect(find.text('应用来源无法确认'), findsOneWidget);
  });

  testWidgets('about page warning ignores startup suppression preference', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      hideAppIntegrityWarningPreferenceKey: true,
    });
    AppIntegrityService().setStatusForTesting(AppIntegrityStatus.untrusted);

    await tester.pumpWidget(_localizedApp(const AboutScreen()));
    await tester.pump();

    expect(find.byType(AppIntegrityWarningCard), findsOneWidget);
    expect(find.text('应用来源无法确认'), findsOneWidget);
    expect(find.text('前往官方网站下载'), findsOneWidget);
  });

  testWidgets('about page does not warn for a trusted app', (tester) async {
    AppIntegrityService().setStatusForTesting(AppIntegrityStatus.trusted);

    await tester.pumpWidget(_localizedApp(const AboutScreen()));
    await tester.pump();

    expect(find.byType(AppIntegrityWarningCard), findsNothing);
  });
}
