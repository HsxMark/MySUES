import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String path) {
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('zh and en ARB files expose the same message keys', () {
    final zh = _messageKeys('lib/l10n/app_zh.arb');
    final en = _messageKeys('lib/l10n/app_en.arb');

    expect(zh.difference(en), isEmpty, reason: 'missing in app_en.arb');
    expect(en.difference(zh), isEmpty, reason: 'missing in app_zh.arb');
  });
}
