import 'package:flutter/material.dart';
import 'package:mysues/services/fold_detection.dart';
import 'package:mysues/services/fold_service.dart';
import 'package:mysues/widgets/fold_filter.dart';

/// Applies the fold animation to the whole app.
///
/// The app is wrapped in a single shader-backed filter: its content keeps
/// living on the flat reference plane and is sampled through the bending glass,
/// so the widget tree is never transformed or duplicated and navigation state,
/// scroll offsets and timers are untouched.
class FoldAppShell extends StatefulWidget {
  const FoldAppShell({super.key, required this.child});

  final Widget child;

  @override
  State<FoldAppShell> createState() => _FoldAppShellState();
}

class _FoldAppShellState extends State<FoldAppShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Moving between the cover and inner panels changes both the geometry and
    // the hinge-to-tilt mapping, so the service is told which one is live.
    FoldService().setInnerPanel(FoldDetection.isInnerPanel(context));
  }

  @override
  Widget build(BuildContext context) {
    final service = FoldService();
    return ListenableBuilder(
      listenable: service,
      child: widget.child,
      builder: (context, child) {
        final inner = service.isInnerPanel;

        final bool axisSwap;
        final double hingeFraction;
        final double paneSide;
        if (inner) {
          axisSwap = FoldDetection.axisSwapOf(context);
          hingeFraction = FoldDetection.hingeFractionOf(context);
          paneSide = service.paneMode.side.toDouble();
        } else {
          // The cover screen is a single pane hinged along the spine, so the
          // whole screen falls on one side of it. Its geometry comes from where
          // the spine sits, not from the pane the user picked.
          final spine = FoldDetection.coverSpineOf(context);
          axisSwap = spine.splitsY;
          hingeFraction = spine.hingeFraction;
          paneSide = spine.paneSide;
        }

        final size = MediaQuery.of(context).size;
        final splitExtentLogical = axisSwap ? size.height : size.width;
        final splitExtentMm = splitExtentLogical / kLogicalPxPerMm;

        return FoldFilter(
          tiltDegrees: service.enabled && service.isFoldable
              ? service.tiltDegrees
              : 0,
          hingeFraction: hingeFraction,
          eyeFraction: inner ? hingeFraction : 0.5,
          paneSide: paneSide,
          eyeDistanceFraction: service.eyeDistanceFraction,
          blurSpread: service.blurSpread,
          darkeningPerMm: service.darkening * FoldService.referencePxPerMm,
          splitExtentMm: splitExtentMm,
          axisSwap: axisSwap,
          child: child!,
        );
      },
    );
  }
}
