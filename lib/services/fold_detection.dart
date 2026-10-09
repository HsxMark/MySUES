import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Flutter's logical pixel is 1/160 inch, so this many fit in a millimetre.
const double kLogicalPxPerMm = 160 / 25.4;

/// Book-style inner displays are close to square; cover screens are tall.
///
/// The same rule duo-open uses to tell the panels apart (`Panels.kt`). This
/// device: inner 1672x2364 -> 1.41, cover 1168x1712 -> 1.47.
const double kInnerMaxAspect = 1.45;

/// Which way the crease runs across the window.
enum FoldCrease {
  /// Crease runs vertically, splitting the window into left and right panels.
  vertical,

  /// Crease runs horizontally, splitting the window into top and bottom panels.
  horizontal,
}

/// Which half of the display bends. The other half is the still reference the
/// fold effect is built around, and stays sharp.
enum FoldPaneMode {
  /// The left (top) half bends.
  left(-1),

  /// The right (bottom) half bends.
  right(1),

  /// Both halves bend, each through half the angle.
  both(0);

  const FoldPaneMode(this.side);

  /// Direction across the split axis, away from the hinge.
  final int side;
}

/// Which edge of the window the cover screen's spine sits on.
///
/// The cover has no crease of its own: it is one pane hinged along the spine,
/// which is fixed to the panel's natural left edge and therefore moves around
/// the window as the device is rotated.
enum FoldSpine {
  left,
  right,
  top,
  bottom;

  /// True when the spine runs horizontally, splitting the y axis.
  bool get splitsY => this == top || this == bottom;

  /// Hinge position along the split axis, 0..1.
  double get hingeFraction => this == left || this == top ? 0 : 1;

  /// Which side of the hinge bends; the whole cover falls on one side of it.
  double get paneSide => this == left || this == top ? 1 : -1;
}

/// The posture the platform reports for the crease.
enum FoldPosture { unknown, flat, halfOpened }

/// Reads the fold geometry the platform reports for the current window.
///
/// Flutter fills [MediaQueryData.displayFeatures] from the Android
/// WindowManager folding feature, so this needs no native call of its own.
abstract final class FoldDetection {
  /// True when this view is on the inner (unfolded) panel rather than the
  /// cover screen.
  ///
  /// A reported crease settles it: only the panel that folds has one. When the
  /// platform reports nothing the panels are told apart by shape, which is
  /// close enough that a wrong answer looks catastrophic - the cover mapping
  /// saturates its tilt where the inner mapping returns to flat.
  static bool isInnerPanel(BuildContext context) {
    if (_usableCreaseOf(context) != null) return true;

    // The measurement comes from the window rather than the platform's
    // [Display], which keeps reporting the default display after the app
    // moves onto the inner panel.
    final size = MediaQuery.sizeOf(context);
    if (size.width <= 0 || size.height <= 0) return false;
    final aspect =
        math.max(size.width, size.height) / math.min(size.width, size.height);
    return aspect < kInnerMaxAspect;
  }

  /// Which edge the cover screen's spine sits on in the current window.
  ///
  /// A phone's cover screen is portrait-native, so in portrait the spine is
  /// still where it naturally sits: the window's left edge. A quarter turn
  /// moves it onto the top or bottom, and the display cutout settles which —
  /// it sits at the panel's natural top, so it shows up as padding along one
  /// side of the window.
  static FoldSpine coverSpineOf(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return FoldSpine.left;
    }
    final padding = MediaQuery.viewPaddingOf(context);
    return padding.right > padding.left ? FoldSpine.top : FoldSpine.bottom;
  }

  /// The crease of the current window, or null when there is none.
  static ui.DisplayFeature? creaseOf(BuildContext context) {
    for (final feature in MediaQuery.of(context).displayFeatures) {
      if (feature.type == ui.DisplayFeatureType.fold ||
          feature.type == ui.DisplayFeatureType.hinge) {
        return feature;
      }
    }
    return null;
  }

  static bool hasCrease(BuildContext context) => creaseOf(context) != null;

  /// The crease, but only while it describes an actual fold region.
  ///
  /// A flat panel still reports a feature, with zero width: harmless as a
  /// "there is a crease here" flag, useless as geometry.
  static ui.DisplayFeature? _usableCreaseOf(BuildContext context) {
    final crease = creaseOf(context);
    if (crease == null) return null;
    final bounds = crease.bounds;
    return bounds.width > 0 && bounds.height > 0 ? crease : null;
  }

  static FoldPosture postureOf(BuildContext context) {
    final crease = creaseOf(context);
    return switch (crease?.state) {
      ui.DisplayFeatureState.postureFlat => FoldPosture.flat,
      ui.DisplayFeatureState.postureHalfOpened => FoldPosture.halfOpened,
      _ => FoldPosture.unknown,
    };
  }

  /// The crease direction, falling back to the window's own aspect ratio when
  /// the platform reports no usable crease geometry.
  static FoldCrease creaseDirectionOf(BuildContext context) {
    final bounds = _usableCreaseOf(context)?.bounds;
    if (bounds != null) {
      return bounds.height >= bounds.width
          ? FoldCrease.vertical
          : FoldCrease.horizontal;
    }
    final size = MediaQuery.sizeOf(context);
    return size.width >= size.height
        ? FoldCrease.vertical
        : FoldCrease.horizontal;
  }

  /// Hinge position along the split axis, 0..1 in window coordinates.
  ///
  /// Falls back to the middle of the window when the platform reports no usable
  /// crease geometry, which is the case whenever the panel is flat.
  static double hingeFractionOf(BuildContext context) {
    final bounds = _usableCreaseOf(context)?.bounds;
    if (bounds != null) {
      final vertical = bounds.height >= bounds.width;
      final centre = vertical ? bounds.center.dx : bounds.center.dy;
      final extent = vertical
          ? MediaQuery.sizeOf(context).width
          : MediaQuery.sizeOf(context).height;
      if (extent > 0) return (centre / extent).clamp(0.0, 1.0);
    }
    return 0.5;
  }

  /// True when the hinge splits the y axis, i.e. the crease runs horizontally.
  static bool axisSwapOf(BuildContext context) =>
      creaseDirectionOf(context) == FoldCrease.horizontal;
}
