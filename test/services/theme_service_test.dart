import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A valid 1x1 PNG so the store can verify that a pick is decodable.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
  'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

String _child(String directory, String name) =>
    '$directory${Platform.pathSeparator}$name';

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

  Future<File> writeSource(String name, List<int> bytes) async {
    final file = File(_child(sources.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  test('loadSettings resolves the stored background', () async {
    final background = await LocalImageStore.background.save(
      (await writeSource('wallpaper.png', _pngBytes)).path,
    );
    ThemeService().resetAfterExternalClear();

    await ThemeService().loadSettings();

    expect(ThemeService().backgroundImagePath, background.path);
  });

  test('loadSettings drops a background that vanished', () async {
    SharedPreferences.setMockInitialValues({
      'background_image_path': _child(
        '/old/container',
        'background_image_missing.jpg',
      ),
    });

    await ThemeService().loadSettings();

    expect(ThemeService().backgroundImagePath, isNull);
  });

  test('updateBackgroundImage publishes the saved file', () async {
    var notifications = 0;
    void listener() => notifications++;
    ThemeService().addListener(listener);
    addTearDown(() => ThemeService().removeListener(listener));

    final source = await writeSource('wallpaper.png', _pngBytes);
    await ThemeService().updateBackgroundImage(source.path);

    final path = ThemeService().backgroundImagePath;
    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(notifications, greaterThan(0));
  });

  test('handleBackgroundImageError ignores other paths', () async {
    final source = await writeSource('wallpaper.png', _pngBytes);
    await ThemeService().updateBackgroundImage(source.path);
    final current = ThemeService().backgroundImagePath;

    await ThemeService().handleBackgroundImageError(
      _child('/tmp', 'other.jpg'),
    );

    expect(ThemeService().backgroundImagePath, current);
    expect(File(current!).existsSync(), isTrue);
  });

  test('handleBackgroundImageError clears the failure', () async {
    final source = await writeSource('wallpaper.png', _pngBytes);
    await ThemeService().updateBackgroundImage(source.path);
    final current = ThemeService().backgroundImagePath!;

    await ThemeService().handleBackgroundImageError(current);

    expect(ThemeService().backgroundImagePath, isNull);
    expect(File(current).existsSync(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('background_image_path'), isNull);
  });

  test('clearBackgroundImage resets the opacity', () async {
    final source = await writeSource('wallpaper.png', _pngBytes);
    await ThemeService().updateBackgroundImage(source.path);
    await ThemeService().updateBackgroundOpacity(0.8);
    final stored = ThemeService().backgroundImagePath!;

    await ThemeService().clearBackgroundImage();

    expect(ThemeService().backgroundImagePath, isNull);
    expect(ThemeService().backgroundOpacity, 0.5);
    expect(File(stored).existsSync(), isFalse);
  });

  test('resetAfterExternalClear drops cached state', () async {
    final source = await writeSource('wallpaper.png', _pngBytes);
    await ThemeService().updateBackgroundImage(source.path);
    await ThemeService().updateBackgroundOpacity(0.9);
    await ThemeService().updateLiquidGlass(true);
    await ThemeService().updateSplashAnimation(true);
    await ThemeService().updateThemeMode(2);

    ThemeService().resetAfterExternalClear();

    expect(ThemeService().backgroundImagePath, isNull);
    expect(ThemeService().backgroundOpacity, 0.5);
    expect(ThemeService().liquidGlassEnabled, isFalse);
    expect(ThemeService().splashAnimationEnabled, isFalse);
    expect(ThemeService().themeMode, ThemeMode.system);
  });
}
