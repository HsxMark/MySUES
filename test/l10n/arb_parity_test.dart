import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chinese and English ARB resources have matching keys', () {
    final zh =
        jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;

    final zhKeys = zh.keys.where((key) => !key.startsWith('@')).toSet();
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(zhKeys), isEmpty);
    expect(zhKeys.difference(enKeys), isEmpty);

    final placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)');
    for (final key in zhKeys) {
      final zhPlaceholders = placeholderPattern
          .allMatches(zh[key] as String)
          .map((match) => match.group(1))
          .toSet();
      final enPlaceholders = placeholderPattern
          .allMatches(en[key] as String)
          .map((match) => match.group(1))
          .toSet();
      expect(
        enPlaceholders,
        zhPlaceholders,
        reason: 'Placeholders differ for $key',
      );
    }
  });
}
