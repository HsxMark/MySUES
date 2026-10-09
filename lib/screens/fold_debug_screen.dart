import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/services/fold_detection.dart';
import 'package:mysues/services/fold_service.dart';
import 'package:mysues/widgets/fold_filter.dart';
import 'package:mysues/widgets/material_you.dart';

/// Shows what the platform reports about folding: the capability probe the
/// native side ran, the window's crease, the live hinge angle, and a preview of
/// the fold effect that can be driven by hand.
class FoldDebugScreen extends StatefulWidget {
  const FoldDebugScreen({super.key});

  @override
  State<FoldDebugScreen> createState() => _FoldDebugScreenState();
}

class _FoldDebugScreenState extends State<FoldDebugScreen> {
  @override
  void initState() {
    super.initState();
    // Keep a live reading flowing even when the animation itself is off.
    FoldService().startWatching();
  }

  @override
  void dispose() {
    FoldService().stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FoldService();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.foldDetectionAndDebug),
        actions: [
          IconButton(
            tooltip: context.l10n.foldRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: service.refreshDiagnostics,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final diagnostics = service.diagnostics;
          final crease = FoldDetection.creaseOf(context);
          final nativeFoldable = service.isFoldable;
          final detected = nativeFoldable || crease != null;

          return ListView(
            children: [
              AppSectionHeader(context.l10n.foldDetectResult),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: AppNoticeBanner(
                  kind: detected
                      ? AppNoticeKind.success
                      : AppNoticeKind.warning,
                  message: detected
                      ? context.l10n.foldDetected
                      : context.l10n.foldNotDetected,
                ),
              ),
              if (service.probed && !nativeFoldable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: AppNoticeBanner(
                      kind: AppNoticeKind.warning,
                      message: context.l10n.foldNoSensorHint,
                    ),
                  ),
                ),
              AppSectionHeader(context.l10n.foldLiveData),
              AppCardSection(
                children: [
                  _ValueTile(
                    label: context.l10n.foldHingeAngle,
                    icon: Icons.threed_rotation,
                    value: service.hingeAngle == null
                        ? context.l10n.foldAngleUnavailable
                        : '${service.hingeAngle!.toStringAsFixed(1)}°',
                  ),
                  _ValueTile(
                    label: context.l10n.foldOpenRatio,
                    icon: Icons.unfold_more,
                    value: service.openRatio == null
                        ? context.l10n.foldAngleUnavailable
                        : '${(service.openRatio! * 100).round()}%',
                  ),
                  _ValueTile(
                    label: context.l10n.foldGlassTilt,
                    icon: Icons.auto_awesome_motion_outlined,
                    value: '${service.tiltDegrees.toStringAsFixed(1)}°',
                  ),
                  _ValueTile(
                    label: context.l10n.foldPanel,
                    icon: Icons.screenshot_monitor_outlined,
                    value: FoldDetection.isInnerPanel(context)
                        ? context.l10n.foldPanelInner
                        : context.l10n.foldPanelCover,
                    subtitle: FoldDetection.isInnerPanel(context)
                        ? null
                        : '${MediaQuery.orientationOf(context).name} · '
                              'pad l${MediaQuery.viewPaddingOf(context).left.round()}'
                              ' t${MediaQuery.viewPaddingOf(context).top.round()}'
                              ' r${MediaQuery.viewPaddingOf(context).right.round()}'
                              ' b${MediaQuery.viewPaddingOf(context).bottom.round()}'
                              ' · spine '
                              '${FoldDetection.coverSpineOf(context).name}',
                  ),
                  _ValueTile(
                    label: context.l10n.foldPosture,
                    icon: Icons.screen_rotation_alt_outlined,
                    value: switch (FoldDetection.postureOf(context)) {
                      FoldPosture.flat => context.l10n.foldPostureFlat,
                      FoldPosture.halfOpened =>
                        context.l10n.foldPostureHalfOpened,
                      FoldPosture.unknown => context.l10n.foldPostureUnknown,
                    },
                  ),
                ],
              ),
              AppSectionHeader(context.l10n.foldPreview),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: _FoldPreview(angle: service.hingeAngle),
              ),
              AppSectionHeader(context.l10n.foldDetectionSignals),
              AppCardSection(
                children: [
                  _ValueTile(
                    label: context.l10n.foldSignalHingeSensor,
                    icon: Icons.sensors,
                    value: _yesNo(
                      context,
                      diagnostics['hingeSensorPresent'] == true,
                    ),
                  ),
                  _ValueTile(
                    label: context.l10n.foldSignalHingeFeature,
                    icon: Icons.verified_outlined,
                    value: _yesNo(
                      context,
                      diagnostics['hingeFeatureFlag'] == true,
                    ),
                  ),
                  _ValueTile(
                    label: context.l10n.foldSignalWindowCrease,
                    icon: Icons.vertical_split_outlined,
                    value: _yesNo(context, crease != null),
                    subtitle: crease == null
                        ? null
                        : '${crease.bounds.width.round()}×'
                              '${crease.bounds.height.round()} · '
                              '${crease.type.name} · ${crease.state.name}',
                  ),
                ],
              ),
              AppSectionHeader(context.l10n.foldSensors),
              _SensorList(diagnostics: diagnostics),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  String _yesNo(BuildContext context, bool value) =>
      value ? context.l10n.foldYes : context.l10n.foldNo;
}

/// A preview of the fold effect over static artwork, so the shader can be
/// judged without folding the phone.
class _FoldPreview extends StatefulWidget {
  const _FoldPreview({required this.angle});

  final double? angle;

  @override
  State<_FoldPreview> createState() => _FoldPreviewState();
}

class _FoldPreviewState extends State<_FoldPreview> {
  /// Overrides the live reading so the effect can be inspected without
  /// folding the phone.
  double? _manualAngle;

  /// Feeds [_manualAngle]'s tilt to the whole app instead of just this preview.
  bool _driveApp = false;

  @override
  Widget build(BuildContext context) {
    final service = FoldService();
    final angle = _manualAngle ?? widget.angle ?? 180;
    final tilt = service.tiltForHinge(angle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.large),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The shader measures distances as fractions of the texture it
                // is filtering, so the preview needs its own extent.
                final splitExtentMm =
                    constraints.maxWidth / kLogicalPxPerMm;
                return FoldFilter(
                  tiltDegrees: tilt,
                  hingeFraction: 0.5,
                  eyeFraction: 0.5,
                  paneSide: service.paneMode.side.toDouble(),
                  eyeDistanceFraction: service.eyeDistanceFraction,
                  blurSpread: service.blurSpread,
                  darkeningPerMm:
                      service.darkening * FoldService.referencePxPerMm,
                  splitExtentMm: splitExtentMm,
                  child: const _PreviewCard(),
                );
              },
            ),
          ),
        ),
        Row(
          children: [
            Text(context.l10n.foldManualPreview),
            Expanded(
              child: Slider(
                value: angle,
                max: 180,
                divisions: 36,
                label: '${angle.round()}°',
                onChanged: (value) {
                  setState(() => _manualAngle = value);
                  if (_driveApp) {
                    FoldService().setDebugTilt(
                      FoldService().tiltForPanel(value),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: 40,
              child: Text('${angle.round()}°', textAlign: TextAlign.end),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.foldPreviewHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(context.l10n.foldDriveApp),
            Switch(
              value: _driveApp,
              onChanged: (value) {
                setState(() => _driveApp = value);
                final manual = _manualAngle;
                FoldService().setDebugTilt(
                  value && manual != null
                      ? FoldService().tiltForPanel(manual)
                      : null,
                );
              },
            ),
            if (_manualAngle != null)
              TextButton(
                onPressed: () {
                  setState(() => _manualAngle = null);
                  FoldService().setDebugTilt(null);
                },
                child: Text(context.l10n.foldFollowDevice),
              ),
          ],
        ),
      ],
    );
  }
}

/// Static artwork for the preview: a grid fine enough that the progressive
/// blur and darkening are visible as they sweep across it.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  static const List<String> _columns = ['一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            for (var row = 0; row < 6; row++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      for (var column = 0; column < _columns.length; column++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: _cell(context, row, column),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int row, int column) {
    final scheme = Theme.of(context).colorScheme;
    final filled = (row + column).isEven;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '${_columns[column]}${row + 1}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: filled ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SensorList extends StatelessWidget {
  const _SensorList({required this.diagnostics});

  final Map<String, Object?> diagnostics;

  @override
  Widget build(BuildContext context) {
    final sensors = <Map<Object?, Object?>>[
      for (final entry in _asList(diagnostics['foldSensors']))
        if (entry is Map) entry,
    ];
    if (sensors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Text(
          context.l10n.foldAngleUnavailable,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return AppCardSection(
      children: [
        for (final sensor in sensors)
          _ValueTile(
            label: '${sensor['name'] ?? ''}',
            icon: Icons.memory_outlined,
            value: '${sensor['stringType'] ?? sensor['type'] ?? ''}',
            subtitle:
                '${sensor['vendor'] ?? ''} · '
                'Δ${sensor['resolution'] ?? '?'} · '
                'max ${sensor['maxRange'] ?? '?'}',
          ),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.icon,
    required this.value,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

List<Object?> _asList(Object? value) =>
    value is List ? value.cast<Object?>() : const <Object?>[];
