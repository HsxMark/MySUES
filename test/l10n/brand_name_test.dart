import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chinese user-facing resources use the current brand name', () {
    const currentBrand = '三旋翼课程表';
    const legacyBrand = '苏伊士';
    const resourcePaths = <String>[
      'lib/l10n/app_zh.arb',
      'lib/l10n/app_localizations.dart',
      'lib/l10n/app_localizations_zh.dart',
      'android/app/src/main/res/values-zh/strings.xml',
      'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
      'macos/Runner/zh-Hans.lproj/InfoPlist.strings',
      'assets/legal/privacy_zh.md',
      'assets/legal/agreement_zh.md',
      'docs/README_zh-Hans.md',
    ];

    final missingCurrentBrand = <String>[];
    final legacyBrandOffenders = <String>[];

    for (final path in resourcePaths) {
      final source = File(path).readAsStringSync();
      if (!source.contains(currentBrand)) {
        missingCurrentBrand.add(path);
      }
      if (source.contains(legacyBrand)) {
        legacyBrandOffenders.add(path);
      }
    }

    expect(
      missingCurrentBrand,
      isEmpty,
      reason: 'Current Chinese brand is missing from these resources',
    );
    expect(
      legacyBrandOffenders,
      isEmpty,
      reason: 'Legacy Chinese brand remains in these resources',
    );
  });
}
