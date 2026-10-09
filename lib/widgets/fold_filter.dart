import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Applies the Duo fold shader to [child].
///
/// The content is never transformed: it stays on the flat reference plane and
/// the shader samples it through the bending frosted glass, so the effect costs
/// one full-screen pass and leaves the widget tree untouched.
class FoldFilter extends StatefulWidget {
  const FoldFilter({
    super.key,
    required this.child,
    required this.tiltDegrees,
    required this.hingeFraction,
    required this.eyeFraction,
    required this.paneSide,
    required this.eyeDistanceFraction,
    required this.blurSpread,
    required this.darkeningPerMm,
    required this.splitExtentMm,
    this.axisSwap = false,
  });

  final Widget child;

  /// Glass tilt. 0 leaves the child untouched and skips the filter entirely.
  final double tiltDegrees;

  /// Hinge position along the split axis, 0..1.
  final double hingeFraction;

  /// Eye position along the split axis, 0..1. It sits on the hinge for a split
  /// screen and at the centre of the window for the single-pane cover screen.
  final double eyeFraction;

  /// Which side of the hinge bends: -1 the half before it along the split axis,
  /// +1 the half after it, 0 both. The other half stays crisp.
  final double paneSide;

  /// Eye distance from the plane, as a multiple of the split axis length.
  final double eyeDistanceFraction;

  final double blurSpread;

  /// Fraction of light lost per millimetre of blur radius.
  final double darkeningPerMm;

  /// Physical length of the split axis, in millimetres.
  final double splitExtentMm;

  /// True when the hinge splits the y axis (a horizontal crease).
  final bool axisSwap;

  @override
  State<FoldFilter> createState() => _FoldFilterState();
}

class _FoldFilterState extends State<FoldFilter> {
  /// Stands in while the shader is still loading, so the tree never changes
  /// shape and the app inside is never remounted.
  static final ui.ImageFilter _inactive = ui.ImageFilter.matrix(
    Matrix4.identity().storage,
  );

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    DuoFoldProgram.load().then((program) {
      if (!mounted || program == null) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader != null && widget.tiltDegrees > 0.05) {
      // Float slots follow the declaration order in duo_fold.frag; the engine
      // owns slots 0 and 1, which carry the texture size.
      shader
        ..setFloat(2, widget.tiltDegrees * math.pi / 180)
        ..setFloat(3, widget.hingeFraction.clamp(0.0, 1.0))
        ..setFloat(4, widget.eyeFraction.clamp(0.0, 1.0))
        ..setFloat(5, widget.eyeDistanceFraction)
        ..setFloat(6, widget.paneSide)
        ..setFloat(7, widget.axisSwap ? 1.0 : 0.0)
        ..setFloat(8, widget.blurSpread)
        ..setFloat(9, widget.darkeningPerMm)
        ..setFloat(10, widget.splitExtentMm);

      return ImageFiltered(
        imageFilter: ui.ImageFilter.shader(shader),
        child: widget.child,
      );
    }

    return ImageFiltered(
      imageFilter: _inactive,
      enabled: false,
      child: widget.child,
    );
  }
}

/// Loads `shaders/duo_fold.frag` once for the whole app.
abstract final class DuoFoldProgram {
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loading;

  /// True when the running engine can use [ui.ImageFilter.shader], which needs
  /// Impeller.
  static bool get isSupported => ui.ImageFilter.isShaderFilterSupported;

  static Future<ui.FragmentProgram?> load() {
    if (!isSupported) return Future<ui.FragmentProgram?>.value();
    return _loading ??= _load();
  }

  static Future<ui.FragmentProgram?> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/duo_fold.frag',
      );
      _program = program;
      return program;
    } catch (error) {
      debugPrint('Duo fold shader failed to load: $error');
      return null;
    }
  }

  static ui.FragmentProgram? get program => _program;
}
