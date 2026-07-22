import 'package:flutter/foundation.dart';
import 'package:flutter_secure_app/flutter_secure_app.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum AppIntegrityStatus { trusted, untrusted, notApplicable }

class AppIntegrityService {
  AppIntegrityService._();

  static final AppIntegrityService _instance = AppIntegrityService._();

  factory AppIntegrityService() => _instance;

  // SHA-256 of the signing certificate, uppercase and without separators.
  static const Set<String> trustedAndroidSignatures = {
    'A95B41613E2E17CD412C688AD0B376BB39BF6FE8F450203C6A863741C87C72B8',
  };

  AppIntegrityStatus _status = AppIntegrityStatus.notApplicable;
  Future<void>? _initialization;

  AppIntegrityStatus get status => _status;
  bool get requiresWarning => _status == AppIntegrityStatus.untrusted;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final shouldCheck =
        !kIsWeb &&
        kReleaseMode &&
        defaultTargetPlatform == TargetPlatform.android;

    _status = await verifyForTesting(
      shouldCheck: shouldCheck,
      secureAppCheck: _checkWithFlutterSecureApp,
      signatureReader: _readAndroidBuildSignature,
    );
  }

  Future<bool> _checkWithFlutterSecureApp() async {
    var threatDetected = false;
    var exceptionReported = false;
    final secureApp = FlutterSecureApp();

    await secureApp.init(
      isEnabled: true,
      isProdEnv: true,
      validAndroidSignatures: trustedAndroidSignatures.toList(growable: false),
      checkJailbreakOrHooking: false,
      checkEmulator: false,
      checkDebugger: false,
      checkAppSignature: true,
      checkOfficialStore: false,
      checkDeviceBinding: false,
      checkDeviceIdSpoofing: false,
      onThreatDetected: (threatType) {
        threatDetected = true;
        debugPrint('App integrity threat detected: $threatType');
      },
      onException: (error, stackTrace) {
        exceptionReported = true;
        debugPrint('App integrity check failed: $error\n$stackTrace');
      },
    );

    return !threatDetected && !exceptionReported && secureApp.isSafe;
  }

  Future<String?> _readAndroidBuildSignature() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildSignature;
  }

  @visibleForTesting
  static Future<AppIntegrityStatus> verifyForTesting({
    required bool shouldCheck,
    required Future<bool> Function() secureAppCheck,
    required Future<String?> Function() signatureReader,
  }) async {
    if (!shouldCheck) return AppIntegrityStatus.notApplicable;

    var secureCheckPassed = false;
    try {
      secureCheckPassed = await secureAppCheck();
    } catch (error, stackTrace) {
      debugPrint('flutter_secure_app check threw: $error\n$stackTrace');
    }

    String? buildSignature;
    try {
      buildSignature = normalizeSignature(await signatureReader());
    } catch (error, stackTrace) {
      debugPrint('Unable to read Android build signature: $error\n$stackTrace');
    }

    if (secureCheckPassed &&
        buildSignature != null &&
        trustedAndroidSignatures.contains(buildSignature)) {
      return AppIntegrityStatus.trusted;
    }

    return AppIntegrityStatus.untrusted;
  }

  @visibleForTesting
  static String? normalizeSignature(String? signature) {
    if (signature == null) return null;

    final normalized = signature
        .replaceAll(':', '')
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();

    if (!RegExp(r'^[0-9A-F]{64}$').hasMatch(normalized)) return null;
    return normalized;
  }

  @visibleForTesting
  void setStatusForTesting(AppIntegrityStatus status) {
    _status = status;
    _initialization = Future.value();
  }

  @visibleForTesting
  void resetForTesting() {
    _status = AppIntegrityStatus.notApplicable;
    _initialization = null;
  }
}
