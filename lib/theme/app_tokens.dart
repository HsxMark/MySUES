import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 16;
}

abstract final class AppRadii {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 20;
  static const double extraLarge = 28;
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  static AppStatusColors light = const AppStatusColors(
    success: Color(0xFF236C2E),
    onSuccess: Colors.white,
    successContainer: Color(0xFFA8F5A9),
    onSuccessContainer: Color(0xFF002107),
    warning: Color(0xFF7A5900),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFDEA1),
    onWarningContainer: Color(0xFF261A00),
  );

  static AppStatusColors dark = const AppStatusColors(
    success: Color(0xFF8CD88F),
    onSuccess: Color(0xFF00390D),
    successContainer: Color(0xFF07521A),
    onSuccessContainer: Color(0xFFA8F5A9),
    warning: Color(0xFFF2C04F),
    onWarning: Color(0xFF402D00),
    warningContainer: Color(0xFF5C4300),
    onWarningContainer: Color(0xFFFFDEA1),
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) => AppStatusColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
  );

  @override
  AppStatusColors lerp(covariant AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>()!;
}
