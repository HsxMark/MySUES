import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/app_integrity_service.dart';

void main() {
  const trustedSignature =
      'A95B41613E2E17CD412C688AD0B376BB39BF6FE8F450203C6A863741C87C72B8';

  group('AppIntegrityService', () {
    test('normalizes colon-separated lowercase SHA-256 fingerprints', () {
      final colonSeparated = trustedSignature
          .toLowerCase()
          .replaceAllMapped(RegExp(r'..'), (match) => '${match.group(0)}:')
          .replaceFirst(RegExp(r':$'), '');

      expect(
        AppIntegrityService.normalizeSignature(colonSeparated),
        trustedSignature,
      );
    });

    test('rejects malformed fingerprints', () {
      expect(AppIntegrityService.normalizeSignature('not-a-hash'), isNull);
      expect(AppIntegrityService.normalizeSignature(''), isNull);
      expect(AppIntegrityService.normalizeSignature(null), isNull);
    });

    test('does not run checks when the platform policy is disabled', () async {
      var secureCheckCalled = false;
      var signatureReaderCalled = false;

      final status = await AppIntegrityService.verifyForTesting(
        shouldCheck: false,
        secureAppCheck: () async {
          secureCheckCalled = true;
          return true;
        },
        signatureReader: () async {
          signatureReaderCalled = true;
          return trustedSignature;
        },
      );

      expect(status, AppIntegrityStatus.notApplicable);
      expect(secureCheckCalled, isFalse);
      expect(signatureReaderCalled, isFalse);
    });

    test('trusts the app only when both checks pass', () async {
      final status = await AppIntegrityService.verifyForTesting(
        shouldCheck: true,
        secureAppCheck: () async => true,
        signatureReader: () async => trustedSignature,
      );

      expect(status, AppIntegrityStatus.trusted);
    });

    test('warns when flutter_secure_app reports a threat', () async {
      final status = await AppIntegrityService.verifyForTesting(
        shouldCheck: true,
        secureAppCheck: () async => false,
        signatureReader: () async => trustedSignature,
      );

      expect(status, AppIntegrityStatus.untrusted);
    });

    test('warns when the directly read signature does not match', () async {
      final status = await AppIntegrityService.verifyForTesting(
        shouldCheck: true,
        secureAppCheck: () async => true,
        signatureReader: () async => List.filled(64, '0').join(),
      );

      expect(status, AppIntegrityStatus.untrusted);
    });

    test('warns when either verification layer throws', () async {
      final secureFailure = await AppIntegrityService.verifyForTesting(
        shouldCheck: true,
        secureAppCheck: () async => throw StateError('secure check failed'),
        signatureReader: () async => trustedSignature,
      );
      final readerFailure = await AppIntegrityService.verifyForTesting(
        shouldCheck: true,
        secureAppCheck: () async => true,
        signatureReader: () async => throw StateError('signature unavailable'),
      );

      expect(secureFailure, AppIntegrityStatus.untrusted);
      expect(readerFailure, AppIntegrityStatus.untrusted);
    });
  });
}
