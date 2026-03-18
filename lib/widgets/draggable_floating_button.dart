import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../services/theme_service.dart';


class DraggableFloatingButton extends StatefulWidget {
  
  final String label;

  
  
  final bool isAtHome;

  
  final VoidCallback onTap;

  
  final double initialDx;

  
  final double initialDy;

  
  final void Function(double dx, double dy)? onPositionChanged;

  const DraggableFloatingButton({
    super.key,
    required this.label,
    required this.isAtHome,
    required this.onTap,
    this.initialDx = -1,
    this.initialDy = -1,
    this.onPositionChanged,
  });

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton> {
  late double _dx;
  late double _dy;
  bool _initialized = false;
  bool _isDragging = false;

  static const double _buttonSize = 56.0;

  @override
  void initState() {
    super.initState();
    _dx = widget.initialDx;
    _dy = widget.initialDy;
  }

  @override
  void didUpdateWidget(DraggableFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    
    if (!_initialized) {
      _dx = widget.initialDx;
      _dy = widget.initialDy;
    }
  }

  void _ensureInitialized(BoxConstraints constraints) {
    if (_initialized) {
      
      _dx = _dx.clamp(0, (constraints.maxWidth - _buttonSize).clamp(0, double.infinity));
      _dy = _dy.clamp(0, (constraints.maxHeight - _buttonSize).clamp(0, double.infinity));
      return;
    }
    
    if (_dx < 0 || _dy < 0) {
      _dx = constraints.maxWidth - _buttonSize - 16;
      _dy = constraints.maxHeight - _buttonSize - 24;
    }
    _dx = _dx.clamp(0, (constraints.maxWidth - _buttonSize).clamp(0, double.infinity));
    _dy = _dy.clamp(0, (constraints.maxHeight - _buttonSize).clamp(0, double.infinity));
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiquidGlass = ThemeService().liquidGlassEnabled;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureInitialized(constraints);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: _dx,
                top: _dy,
                child: GestureDetector(
                  onPanStart: (_) {
                    _isDragging = false;
                  },
                  onPanUpdate: (details) {
                    _isDragging = true;
                    setState(() {
                      _dx = (_dx + details.delta.dx).clamp(
                        0,
                        (constraints.maxWidth - _buttonSize).clamp(0, double.infinity),
                      );
                      _dy = (_dy + details.delta.dy).clamp(
                        0,
                        (constraints.maxHeight - _buttonSize).clamp(0, double.infinity),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    if (_isDragging) {
                      widget.onPositionChanged?.call(_dx, _dy);
                    }
                    _isDragging = false;
                  },
                  onTap: () {
                    if (!_isDragging) {
                      widget.onTap();
                    }
                },
                child: _buildButton(theme, colorScheme, isLiquidGlass),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildButton(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLiquidGlass,
  ) {
    final bgColor = widget.isAtHome
        ? colorScheme.primaryContainer
        : colorScheme.primary;
    final fgColor = widget.isAtHome
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimary;

    final child = SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: Center(
        child: Icon(Icons.calendar_today_rounded, color: fgColor, size: 24),
      ),
    );

    if (isLiquidGlass) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      final isDark = brightness == Brightness.dark;
      return LiquidGlassLayer(
        settings: LiquidGlassSettings(
          refractiveIndex: 1.21,
          thickness: 30,
          blur: 8,
          saturation: 1.5,
          lightIntensity: isDark ? .7 : 1,
          ambientStrength: isDark ? .2 : .5,
          lightAngle: math.pi / 4,
          glassColor: bgColor.withValues(alpha: 0.6),
        ),
        child: LiquidGlass.grouped(
          shape: const LiquidOval(),
          child: GlassGlow(child: child),
        ),
      );
    }

    return Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
