import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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

/// Course color selector: a collapsible section holding the classic and Morandi
/// preset groups, the saved "My Colors" list and an entry point for picking an
/// arbitrary color.
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
  bool _expanded = false;
  List<String> _savedHexes = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadSavedColors();
  }

  Future<void> _loadSavedColors() async {
    final colors = await CourseColorStore.loadSavedColors();
    if (!mounted) return;
    setState(() => _savedHexes = colors);
  }

  Future<void> _openCustomColorSheet() async {
    final hex = await showCourseColorPickerSheet(
      context: context,
      initialHex: widget.selectedHex,
    );
    if (hex == null || !mounted) return;
    widget.onChanged(hex);
  }

  Future<void> _saveCurrentColor() async {
    final l10n = context.l10n;
    final hex = normalizeCourseColorHex(widget.selectedHex);
    if (hex == null) return;

    if (_savedHexes.contains(hex)) {
      _showMessage(l10n.colorAlreadySaved);
      return;
    }
    if (_savedHexes.length >= CourseColorStore.maxSavedColors) {
      _showMessage(
        l10n.savedColorsLimitReached(CourseColorStore.maxSavedColors),
      );
      return;
    }

    final colors = await CourseColorStore.addSavedColor(hex);
    if (!mounted) return;
    setState(() => _savedHexes = colors);
    _showMessage(l10n.colorSaved);
  }

  Future<void> _deleteSavedColor(String hex) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSavedColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: courseColorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(dialogContext).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(hex, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.savedColorDeleteNotice),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final colors = await CourseColorStore.removeSavedColor(hex);
    if (!mounted) return;
    setState(() => _savedHexes = colors);
  }

  void _showMessage(String message) {
    // Replace the previous hint so rapid taps do not queue stale messages.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selectedColor =
        courseColorFromHex(widget.selectedHex) ?? CoursePalette.classic.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('course-color-toggle'),
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
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
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.selectedHex,
                  key: const ValueKey('course-color-selected-hex'),
                  style: theme.textTheme.labelLarge,
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _buildPanel(context, l10n)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroup(context, l10n.classicColors, CoursePalette.classic),
          const SizedBox(height: AppSpacing.lg),
          _buildGroup(context, l10n.morandiColors, CoursePalette.morandi),
          const SizedBox(height: AppSpacing.lg),
          _buildSavedGroup(context, l10n),
        ],
      ),
    );
  }

  Widget _buildCustomColorButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Tooltip(
      message: l10n.customColor,
      child: InkWell(
        key: const ValueKey('course-color-custom'),
        onTap: _openCustomColorSheet,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(
            Icons.palette_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedGroup(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return _buildSwatchGroup(context, l10n.myColors, [
      for (final hex in _savedHexes)
        _ColorSwatch(
          key: ValueKey('saved-color-$hex'),
          color: courseColorFromHex(hex) ?? CoursePalette.classic.first,
          selected: hex == widget.selectedHex,
          onTap: () => widget.onChanged(hex),
          onLongPress: () => _deleteSavedColor(hex),
        ),
      Tooltip(
        message: l10n.saveColor,
        child: InkWell(
          key: const ValueKey('course-color-save'),
          onTap: _saveCurrentColor,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
          ),
        ),
      ),
      _buildCustomColorButton(context, l10n),
    ]);
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
    this.onLongPress,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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

  @override
  void initState() {
    super.initState();
    final color =
        courseColorFromHex(widget.initialHex) ?? CoursePalette.classic.first;
    _hsv = HSVColor.fromColor(color);
    _hexController = TextEditingController(text: courseColorToHex(color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
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

  void _confirm() {
    final hex = normalizeCourseColorHex(_hexController.text);
    if (hex == null) return;
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
