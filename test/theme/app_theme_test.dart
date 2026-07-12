import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:mysues/theme/app_tokens.dart';

void main() {
  group('AppTheme', () {
    test('builds Material 3 light and dark themes from the brand seed', () {
      final light = AppTheme.light(null);
      final dark = AppTheme.dark('MiSans');

      expect(light.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(dark.textTheme.bodyMedium?.fontFamily, contains('MiSans'));
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('provides component themes and semantic status colors', () {
      final theme = AppTheme.light(null);

      expect(theme.navigationBarTheme.indicatorColor, isNotNull);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      expect(theme.extension<AppStatusColors>(), isNotNull);
    });
  });
}
