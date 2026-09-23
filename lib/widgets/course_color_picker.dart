import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/course_color_store.dart';
import '../theme/app_tokens.dart';
import '../theme/course_palette.dart';

/// Opens the custom color sheet and resolves with the chosen `#RRGGBB` value,
/// or null when the user dismisses it.
Future<String?> showCourseColorPickerSheet({
  required BuildContext context,
  required String initialHex,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CustomColorSheet(initialHex: initialHex),
  );
}

/// Course color selector: the classic and Morandi preset groups, the recently
/// used custom colors, and an entry point for picking an arbitrary color.
class CourseColorPicker extends StatefulWidget {
  const CourseColorPicker({
    super.key,
    required this.selectedHex,
    required this.onChanged,
  });

  /// Currently selected color as `#RRGGBB`.
  final String selectedHex;

  /// Called with the new `#RRGGBB` value whenever the selection changes.
  final ValueChanged<String> onChanged;

  @override
  State<CourseColorPicker> createState() => _CourseColorPickerState();
}

class _CourseColorPickerState extends State<CourseColorPicker> {
  List<String> _recentHexes = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadRecentColors();
  }

  Future<void> _loadRecentColors() async {
    final colors = await CourseColorStore.loadRecentColors();
    if (!mounted) return;
    setState(() => _recentHexes = colors);
  }

  Future<void> _openCustomColorSheet() async {
    final hex = await showCourseColorPickerSheet(
      context: context,
      initialHex: widget.selectedHex,
    );
    if (hex == null || !mounted) return;
    widget.onChanged(hex);
    await _loadRecentColors();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selectedColor =
        courseColorFromHex(widget.selectedHex) ?? CoursePalette.classic.first;

    // Preset colors are already visible in their own group.
    final presetHexes = CoursePalette.all.map(courseColorToHex).toSet();
    final recentHexes = _recentHexes
        .where((hex) => !presetHexes.contains(hex))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.courseColor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.selectedHex,
              key: const ValueKey('course-color-selected-hex'),
              style: theme.textTheme.labelLarge,
            ),
            TextButton.icon(
              key: const ValueKey('course-color-custom'),
              onPressed: _openCustomColorSheet,
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: Text(l10n.customColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildGroup(context, l10n.classicColors, CoursePalette.classic),
        const SizedBox(height: AppSpacing.lg),
        _buildGroup(context, l10n.morandiColors, CoursePalette.morandi),
        if (recentHexes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildHexGroup(context, l10n.recentColors, recentHexes),
        ],
      ],
    );
  }

  Widget _buildGroup(BuildContext context, String label, List<Color> colors) {
    return _buildSwatchGroup(context, label, [
      for (final color in colors)
        _ColorSwatch(
          key: ValueKey('course-color-${courseColorToHex(color)}'),
          color: color,
          selected: courseColorToHex(color) == widget.selectedHex,
          onTap: () => widget.onChanged(courseColorToHex(color)),
        ),
    ]);
  }

  Widget _buildHexGroup(
    BuildContext context,
    String label,
    List<String> hexes,
  ) {
    return _buildSwatchGroup(context, label, [
      for (final hex in hexes)
        _ColorSwatch(
          key: ValueKey('course-color-$hex'),
          color: courseColorFromHex(hex) ?? CoursePalette.classic.first,
          selected: hex == widget.selectedHex,
          onTap: () => widget.onChanged(hex),
        ),
    ]);
  }

  Widget _buildSwatchGroup(
    BuildContext context,
    String label,
    List<Widget> swatches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 12, runSpacing: 12, children: swatches),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
        ),
        child: selected ? Icon(Icons.check, color: checkColor, size: 20) : null,
      ),
    );
  }
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({required this.initialHex});

  final String initialHex;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late final TextEditingController _hexController;
  late HSVColor _hsv;
  String? _errorText;
  List<String> _recentHexes = const <String>[];

  @override
  void initState() {
    super.initState();
    final color =
        courseColorFromHex(widget.initialHex) ?? CoursePalette.classic.first;
    _hsv = HSVColor.fromColor(color);
    _hexController = TextEditingController(text: courseColorToHex(color));
    _loadRecentColors();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentColors() async {
    final colors = await CourseColorStore.loadRecentColors();
    if (!mounted) return;
    setState(() => _recentHexes = colors);
  }

  void _applyHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _errorText = null;
      _hexController.text = courseColorToHex(hsv.toColor());
    });
  }

  void _applyHexInput(String raw) {
    final cleaned = raw.trim().replaceFirst('#', '');
    final hex = normalizeCourseColorHex(cleaned);
    final color = hex == null ? null : courseColorFromHex(hex);

    setState(() {
      if (color == null) {
        // Incomplete input is fine while typing; flag it once it looks final.
        _errorText = cleaned.length >= 6 ? context.l10n.invalidHexColor : null;
        return;
      }
      _errorText = null;
      _hsv = HSVColor.fromColor(color);
    });
  }

  Future<void> _confirm() async {
    final hex = normalizeCourseColorHex(_hexController.text);
    if (hex == null) return;
    await CourseColorStore.addRecentColor(hex);
    if (!mounted) return;
    Navigator.of(context).pop(hex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = _hsv.toColor();
    final canConfirm = normalizeCourseColorHex(_hexController.text) != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.chooseColor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  courseColorToHex(color),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSlider(
              label: l10n.hue,
              valueLabel: '${_hsv.hue.round()}°',
              value: _hsv.hue,
              max: 360,
              divisions: 360,
              onChanged: (value) => _applyHsv(_hsv.withHue(value)),
            ),
            _buildSlider(
              label: l10n.saturation,
              valueLabel: '${(_hsv.saturation * 100).round()}%',
              value: _hsv.saturation,
              max: 1,
              divisions: 100,
              onChanged: (value) => _applyHsv(_hsv.withSaturation(value)),
            ),
            _buildSlider(
              label: l10n.brightness,
              valueLabel: '${(_hsv.value * 100).round()}%',
              value: _hsv.value,
              max: 1,
              divisions: 100,
              onChanged: (value) => _applyHsv(_hsv.withValue(value)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('course-color-hex-field'),
              controller: _hexController,
              onChanged: _applyHexInput,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.hexColorCode,
                hintText: '#A8707A',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
            ),
            if (_recentHexes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.recentColors,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final hex in _recentHexes)
                    _ColorSwatch(
                      key: ValueKey('recent-color-$hex'),
                      color:
                          courseColorFromHex(hex) ??
                          CoursePalette.classic.first,
                      selected:
                          normalizeCourseColorHex(_hexController.text) == hex,
                      onTap: () {
                        final recentColor = courseColorFromHex(hex);
                        if (recentColor == null) return;
                        _applyHsv(HSVColor.fromColor(recentColor));
                        _hexController.text = hex;
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: const ValueKey('course-color-confirm'),
                  onPressed: canConfirm ? _confirm : null,
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueLabel,
    required double value,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
