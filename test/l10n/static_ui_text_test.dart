import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI code does not use the legacy translation layer', () {
    expect(File('lib/l10n/legacy_text.dart').existsSync(), isFalse);

    final offenders = <String>[];
    for (final file in _uiFiles()) {
      final source = file.readAsStringSync();
      if (source.contains('LText(') || source.contains('legacyTranslate(')) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('UI string literals contain no unapproved Chinese copy', () {
    final offenders = <String>[];
    final han = RegExp(r'[\u3400-\u9fff]');

    for (final file in _uiFiles()) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final code = lines[index].split('//').first;
        if (!han.hasMatch(code)) continue;
        if (_isAllowed(normalizedPath, code)) continue;
        offenders.add('$normalizedPath:${index + 1}: ${code.trim()}');
      }
    }

    expect(offenders, isEmpty);
  });
}

Iterable<File> _uiFiles() sync* {
  for (final root in ['lib/screens', 'lib/widgets']) {
    yield* Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }
  yield File('lib/utils/sync_disclaimer.dart');
}

bool _isAllowed(String path, String code) {
  if (path.endsWith('/add_exam_screen.dart') && code.contains("'未结束'")) {
    return true;
  }
  if (path.endsWith('/login_webview_screen.dart') &&
      code.contains('contains("登录")')) {
    return true;
  }
  if (path.endsWith('/acknowledgements_screen.dart')) {
    return true;
  }
  return false;
}
