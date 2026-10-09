import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/screens/fold_debug_screen.dart';
import 'package:mysues/services/fold_detection.dart';
import 'package:mysues/services/fold_service.dart';
import 'package:mysues/widgets/material_you.dart';

/// Everything the fold animation can be told to do, one level down from the
/// settings list.
class FoldSettingsScreen extends StatefulWidget {
  const FoldSettingsScreen({super.key});

  @override
  State<FoldSettingsScreen> createState() => _FoldSettingsScreenState();
}

class _FoldSettingsScreenState extends State<FoldSettingsScreen> {
  double? _blurPreview;
  double? _darkenPreview;
  double? _distancePreview;

  @override
  Widget build(BuildContext context) {
    final service = FoldService();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.foldable),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) => ListView(
          children: [
            AppSectionHeader(context.l10n.foldable),
            AppCardSection(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.unfold_more),
                  title: Text(context.l10n.foldAnimation),
                  subtitle: Text(context.l10n.foldAnimationSubtitle),
                  value: service.enabled,
                  onChanged: (value) => service.setEnabled(value),
                ),
                ListTile(
                  leading: const Icon(Icons.vertical_split_outlined),
                  title: Text(context.l10n.foldPaneMode),
                  subtitle: Text(_paneModeName(context, service.paneMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickPaneMode,
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(context.l10n.foldDetectionAndDebug),
                  subtitle: Text(context.l10n.foldDetectionAndDebugSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoldDebugScreen(),
                    ),
                  ),
                ),
              ],
            ),
            AppSectionHeader(context.l10n.foldTuning),
            AppCardSection(
              children: [
                _SliderRow(
                  label: context.l10n.foldIntensity,
                  value: service.intensity,
                  min: FoldService.minIntensity,
                  max: FoldService.maxIntensity,
                  display: service.intensity.toStringAsFixed(2),
                  onChanged: (value) => service.setIntensity(value),
                  onChangeEnd: (value) => service.setIntensity(value),
                ),
                _SliderRow(
                  label: context.l10n.foldBlurSpread,
                  value: _blurPreview ?? service.blurSpread,
                  min: FoldService.minBlurSpread,
                  max: FoldService.maxBlurSpread,
                  display: (_blurPreview ?? service.blurSpread)
                      .toStringAsFixed(3),
                  onChanged: (value) => setState(() => _blurPreview = value),
                  onChangeEnd: (value) async {
                    await service.setBlurSpread(value);
                    setState(() => _blurPreview = null);
                  },
                ),
                _SliderRow(
                  label: context.l10n.foldDarkening,
                  value: _darkenPreview ?? service.darkening,
                  min: FoldService.minDarkening,
                  max: FoldService.maxDarkening,
                  display: (_darkenPreview ?? service.darkening)
                      .toStringAsFixed(3),
                  onChanged: (value) => setState(() => _darkenPreview = value),
                  onChangeEnd: (value) async {
                    await service.setDarkening(value);
                    setState(() => _darkenPreview = null);
                  },
                ),
                _SliderRow(
                  label: context.l10n.foldEyeDistance,
                  value: _distancePreview ?? service.eyeDistanceMm,
                  min: FoldService.minEyeDistanceMm,
                  max: FoldService.maxEyeDistanceMm,
                  display:
                      '${(_distancePreview ?? service.eyeDistanceMm).round()} mm',
                  onChanged: (value) => setState(() => _distancePreview = value),
                  onChangeEnd: (value) async {
                    await service.setEyeDistanceMm(value);
                    setState(() => _distancePreview = null);
                  },
                ),
                _SliderRow(
                  label: context.l10n.foldDeadZone,
                  value: service.deadZone,
                  min: FoldService.minDeadZone,
                  max: FoldService.maxDeadZone,
                  display: '${service.deadZone.round()}°',
                  onChanged: (value) => service.setDeadZone(value),
                  onChangeEnd: (value) => service.setDeadZone(value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _paneModeName(BuildContext context, FoldPaneMode mode) =>
      switch (mode) {
        FoldPaneMode.left => context.l10n.foldPaneLeft,
        FoldPaneMode.right => context.l10n.foldPaneRight,
        FoldPaneMode.both => context.l10n.foldPaneBoth,
      };

  void _pickPaneMode() {
    final service = FoldService();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FoldPaneMode.values.map((mode) {
            return ListTile(
              leading: const Icon(Icons.vertical_split_outlined),
              title: Text(_paneModeName(sheetContext, mode)),
              trailing: service.paneMode == mode
                  ? Icon(
                      Icons.check,
                      color: Theme.of(sheetContext).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                await service.setPaneMode(mode);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                display,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
