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
/// * [glassBall] — the schedule FAB: a real shader lens with the timetable
///   refracting through it, and the ring + icon drawn by Flutter above it.
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

  /// The ball's own box, keyed so the overlay can *measure* it instead of
  /// reconstructing its position from a parent origin and the stored offset —
  /// that arithmetic was measurably wrong (the ball landed 200 px off after a
  /// shell rebuild), while measuring the real render box cannot drift.
  static final GlobalKey ballKey = GlobalKey();

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

  /// The schedule FAB ball: a shader lens as the base, with the hairline ring
  /// and the icon painted by Flutter above it.
  ///
  /// The ring is deliberately **not** the lens' own border. That one is an
  /// optical rim shaped by light intensity and ambient strength, not a
  /// constant hairline — the 1 px outline this widget is recognised by has to
  /// stay a plain 1 px outline. The child therefore inherits the ring colour
  /// and sits on the lens, exactly as the non-glass button draws it.
  ///
  /// Draw this **above the glass shell, never inside its body.** A lens inside
  /// `LiquidGlassScaffold`'s body paints nothing: the scaffold hands that body
  /// to `LiquidGlassView` as its `backgroundWidget`, i.e. the very widget the
  /// view captures, so a lens in there samples the image it is drawn into and
  /// its own output never reaches the screen. Measured on the Xiaomi Pad 5
  /// (Android 14, Impeller, package 4.3.1): with the ball and with the ball
  /// dragged away, eight points sampled from the centre out to r=40 were
  /// byte-identical; the same lens renders as soon as it is a sibling of the
  /// scaffold. [GlassBallOverlay] is what puts it in the right place.
  static Widget glassBall(
    BuildContext context, {
    required Widget child,
    double size = 56,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = _isDark(context);
    final ringColor = isDark ? Colors.white : scheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: LiquidGlassLens(
              style: LiquidGlassStyle(
                // The lens' own optical rim stays on, *under* the Flutter
                // outline: it is the lit edge that still reads as glass on a
                // flat background, where a bare blur is invisible. Values are
                // the package's own tuned FAB rim.
                shape: LiquidGlassShape.roundedRectangle(
                  cornerRadius: size / 2,
                  borderWidth: 1.2,
                  lightIntensity: 1.2,
                  lightDirection: 80,
                  borderType: const OpticalBorder(
                    borderSaturation: 1.3,
                    ambientIntensity: 1.0,
                    borderSolidity: 0.4,
                  ),
                ),
                appearance: LiquidGlassAppearance(
                  // Thin, neutral tint. The glass has to stay transparent
                  // enough to be glass — a heavier fill reads as a frosted
                  // disc, which is the look this deliberately avoids.
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.13),
                  // Frost, but only just: the refraction lives in a band
                  // hugging the rim, and a heavy blur smears it away.
                  blur: const LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
                  saturation: 1.5,
                  // No contact shadow: around a ball this small it reads as a
                  // dirty smudge rather than depth.
                ),
                // Physical refraction (Snell's law off a 3D surface normal):
                // `refraction` is a real refractive index and `depth` is a
                // straight strength dial, unlike the legacy anchor distortion
                // whose shader factor `1 + d*100 * pow(t, d*100)` quietly
                // collapses back to 1 past d ~ 0.2. `refractionWidth` is how
                // far in from the rim the bevel reaches — 40 spans the whole
                // interior of a 56 px ball, so the timetable bends across it
                // rather than only at the edge.
                refraction: const LiquidGlassRefraction(
                  refractionType: OpticalRefraction(
                    refraction: 1.7,
                    refractionWidth: 40,
                    depth: 0.45,
                  ),
                  chromaticAberration: 0,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 1.0),
              ),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: ringColor),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the schedule ball currently is, in screen coordinates.
///
/// The glass cannot be painted where the button lives: `LiquidGlassScaffold`
/// hands its `body` to `LiquidGlassView` as the widget it captures, and a lens
/// inside that capture renders nothing (measured on Android/Impeller — with the
/// ball and without it, the ball's interior is pixel-identical). So the button
/// reports its rect here and [GlassBallOverlay] paints the ball above the
/// shell, where a lens does render.
class GlassBallAnchor extends ValueNotifier<Rect?> {
  GlassBallAnchor._() : super(null);

  static final GlassBallAnchor instance = GlassBallAnchor._();

  void report(Rect? rect) {
    if (rect != value) value = rect;
  }
}

/// The schedule ball, drawn above the glass shell.
///
/// Mount it as the last child of the shell's `Stack` (and keep the button
/// itself as the invisible hit area). Never takes a pointer: the drag and tap
/// belong to the button underneath.
class GlassBallOverlay extends StatelessWidget {
  const GlassBallOverlay({super.key, required this.visible});

  /// Whether the schedule tab is the one on screen.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Re-measure the ball's real box each time this builds (it builds when the
    // ball is shown, hidden or moved), so a shell relayout that the button did
    // not hear about cannot leave the glass behind.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = GlassStyles.ballKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        GlassBallAnchor.instance.report(box.localToGlobal(Offset.zero) & box.size);
      }
    });

    return IgnorePointer(
      child: ValueListenableBuilder<Rect?>(
        valueListenable: GlassBallAnchor.instance,
        builder: (context, rect, _) {
          if (rect == null) return const SizedBox.shrink();
          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: GlassStyles.glassBall(
                  context,
                  child: const Icon(Icons.calendar_today_rounded, size: 24),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
