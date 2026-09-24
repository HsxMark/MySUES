import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/screens/settings/display_settings_screen.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A valid 1x1 PNG so the store can verify that a pick is decodable.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
  'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

String _child(String directory, String name) =>
    '$directory${Platform.pathSeparator}$name';

Widget _displayApp() {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const DisplaySettingsScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late Directory sources;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    documents = await Directory.systemTemp.createTemp('mysues_documents_test');
    sources = await Directory.systemTemp.createTemp('mysues_sources_test');
    LocalImageStore.documentsDirectoryOverride = () async => documents;
    ThemeService().resetAfterExternalClear();
  });

  tearDown(() async {
    LocalImageStore.documentsDirectoryOverride = null;
    for (final directory in [documents, sources]) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });

  testWidgets('a vanished background file is reported as not set', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'background_image_path': _child(
        documents.path,
        'background_image_missing.jpg',
      ),
    });

    // Real file access has to happen outside the fake async zone that widget
    // tests run in, otherwise the awaited file futures never complete.
    await tester.runAsync(() => ThemeService().loadSettings());
    expect(ThemeService().backgroundImagePath, isNull);

    await tester.pumpWidget(_displayApp());
    await tester.pump();

    expect(find.text('未设置'), findsOneWidget);
    expect(find.text('已设置'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stored background shows as set with its preview', (
    tester,
  ) async {
    final source = File(_child(sources.path, 'wallpaper.png'));
    await tester.runAsync(() async {
      await source.writeAsBytes(_pngBytes);
      await ThemeService().updateBackgroundImage(source.path);
    });

    await tester.pumpWidget(_displayApp());
    await tester.pump();

    expect(find.text('已设置'), findsOneWidget);
    expect(find.text('未设置'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
