import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Glass looks for MySUES — used **only** while the Liquid Glass switch is
/// on; with the switch off every screen keeps its plain Material path
/// untouched.
///
/// There are deliberately two flavours here:
///
/// * [frostedPanel] — Flutter's own [BackdropFilter]: backdrop blur,
///   translucent fill, hairline outline, soft shadow. Cards, sheets and
///   pop-up menus all use it, because it lays out, scrolls and animates
///   without surprises.
/// * Schedule FAB — liquid glass base + theme/white hairline ring
///   (readable over the timetable; not a solid opaque button).
///
/// Why the shader glass stays away from ordinary panels (every point below
/// was reproduced on a Pixel-class Android device, Impeller/Vulkan):
///
/// * A lens is invisible over a flat light page (a blur of white is white),
///   so it only reads over a wallpaper.
/// * A lens inside a scrollable goes **black** while Android's stretch
///   overscroll has the list in its own layer — see [scrollable].
/// * A lens in a `showGeneralDialog` menu opens mis-laid-out: the glass is
///   squeezed to a sliver for the first frames while its content is already
///   full width.
/// * Some child geometry (a default Material `Divider`, for one) makes a
///   lens paint a solid black band.
class GlassStyles {
  GlassStyles._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// A frosted panel: backdrop blur + translucent fill + hairline outline.
  static Widget frostedPanel(
    BuildContext context, {
    required Widget child,
    double radius = 24,
    double blur = 16,
    Color? tint,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = _isDark(context);
    final borderRadius = BorderRadius.circular(radius);

    final Widget panel = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                tint ??
                (isDark
                    // A dark page needs a lift, a light one a touch of shade.
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? scheme.primary.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child:
              padding == null ? child : Padding(padding: padding, child: child),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: panel,
    );
  }

  /// Wraps a scrollable that contains frosted panels.
  ///
  /// Android's stretch overscroll puts a dragged list in its own compositing
  /// layer, and a backdrop blur inside that layer can no longer see what is
  /// behind it — it paints black. Turning the indicator off avoids it.
  static Widget scrollable({required Widget child}) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: child,
    );
  }

  /// Card / panel surface on a page (「我的」页卡片 and friends).
  static Widget frosted(
    BuildContext context, {
    required Widget child,
    double radius = 24,
    Color? tint,
  }) {
    return frostedPanel(
      context,
      radius: radius,
      tint: tint,
      child: child,
    );
  }

  /// Pop-up panel: menus and bottom-sheet bodies.
  static Widget lens(
    BuildContext context, {
    required Widget child,
    double radius = 16,
    bool sheet = false,
    bool panel = false,
  }) {
    return frostedPanel(
      context,
      radius: radius,
      // Sheets are tall surfaces — a lighter veil keeps their content crisp.
      tint: sheet || panel
          ? null
          : (_isDark(context)
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.60)),
      padding: EdgeInsets.zero,
      // These panels usually wrap a scrolling body, and a backdrop blur
      // inside a scrollable goes black the moment the list overscrolls —
      // see [scrollable].
      child: GlassStyles.scrollable(
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  /// 課表悬浮球 — liquid glass base + theme/white hairline ring.
  ///
  /// The ball still refracts the timetable behind it; the ring and a light
  /// primary/white tint keep it readable on busy grids.
  static Widget fabShell(
    BuildContext context, {
    required Widget child,
    Color? tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = _isDark(context);
    final ringColor = isDark ? Colors.white : scheme.primary;
    final glassTint =
        tint ?? scheme.primary.withValues(alpha: isDark ? 0.35 : 0.42);

    return SizedBox(
      width: 56,
      height: 56,
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: 28,
            borderWidth: 1.0,
            borderColor: ringColor,
            lightColor: Colors.white,
            lightIntensity: isDark ? 0.9 : 1.1,
            lightDirection: 70,
            borderType: const OpticalBorder(ambientIntensity: 0.7),
          ),
          appearance: LiquidGlassAppearance(
            color: glassTint,
            blur: const LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
            saturation: 1.25,
          ),
          refraction: const LiquidGlassRefraction(
            distortion: 0.12,
            distortionWidth: 22,
          ),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: ringColor, size: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}
