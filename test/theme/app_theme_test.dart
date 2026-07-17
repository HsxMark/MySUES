import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/theme/app_theme.dart';
import 'package:mysues/theme/app_tokens.dart';

void main() {
  group('AppTheme', () {
    test('builds Material 3 light and dark themes from the brand seed', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.textTheme.bodyMedium, isNotNull);
      expect(dark.textTheme.bodyMedium, isNotNull);
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('provides component themes and semantic status colors', () {
      final theme = AppTheme.light();

      expect(theme.navigationBarTheme.indicatorColor, isNotNull);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      expect(theme.extension<AppStatusColors>(), isNotNull);
    });
  });
}
