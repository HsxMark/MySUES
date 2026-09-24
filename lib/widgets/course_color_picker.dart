import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/course_color_store.dart';
import '../theme/app_tokens.dart';
import '../theme/course_palette.dart';

/// What the color sheet resolved with.
@immutable
class CourseColorSheetResult {
  const CourseColorSheetResult.saved(String this.hex) : deleted = false;

  const CourseColorSheetResult.deleted() : hex = null, deleted = true;

  /// Chosen `#RRGGBB`, null when the saved color was deleted instead.
  final String? hex;

  /// True when the user deleted the saved color from the editor.
  final bool deleted;
}

/// Opens the custom color sheet. Resolves with the chosen color, with a delete
/// request, or with null when the user dismisses the sheet.
///
/// Pass [allowDelete] when editing an already saved color to show the delete
/// action at the leading edge of the button row.
Future<CourseColorSheetResult?> showCourseColorPickerSheet({
  required BuildContext context,
  required String initialHex,
  bool allowDelete = false,
}) {
  return showModalBottomSheet<CourseColorSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The theme already renders a drag handle; this sheet draws its own.
    showDragHandle: false,
    builder: (_) =>
        _CustomColorSheet(initialHex: initialHex, allowDelete: allowDelete),
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

  /// Asks for a color and stores it in "My Colors" without touching the course.
  Future<void> _addSavedColor() async {
    final l10n = context.l10n;
    final result = await showCourseColorPickerSheet(
      context: context,
      initialHex: widget.selectedHex,
    );
    final hex = result?.hex;
    if (hex == null || !mounted) return;

    if (_savedHexes.contains(hex)) {
      _showMessage(l10n.colorAlreadySaved);
      return;
    }

    final colors = await CourseColorStore.addSavedColor(hex);
    if (!mounted) return;
    setState(() => _savedHexes = colors);
    _showMessage(l10n.colorSaved);
  }

  /// Long pressing a saved color opens its editor right away.
  ///
  /// Confirming replaces it in place, deleting removes it from the list.
  /// Courses keep the color they already have either way.
  Future<void> _editSavedColor(String hex) async {
    final l10n = context.l10n;
    final result = await showCourseColorPickerSheet(
      context: context,
      initialHex: hex,
      allowDelete: true,
    );
    if (result == null || !mounted) return;

    if (result.deleted) {
      final colors = await CourseColorStore.removeSavedColor(hex);
      if (!mounted) return;
      setState(() => _savedHexes = colors);
      return;
    }

    final updated = result.hex;
    if (updated == null || updated == hex) return;
    if (_savedHexes.contains(updated)) {
      _showMessage(l10n.colorAlreadySaved);
      return;
    }

    final colors = await CourseColorStore.replaceSavedColor(hex, updated);
    if (!mounted) return;
    setState(() => _savedHexes = colors);
    _showMessage(l10n.colorUpdated);
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

  Widget _buildSavedGroup(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final canAddMore = _savedHexes.length < CourseColorStore.maxSavedColors;
    return _buildSwatchGroup(context, l10n.myColors, [
      for (final hex in _savedHexes)
        _ColorSwatch(
          key: ValueKey('saved-color-$hex'),
          color: courseColorFromHex(hex) ?? CoursePalette.classic.first,
          selected: hex == widget.selectedHex,
          onTap: () => widget.onChanged(hex),
          onLongPress: () => _editSavedColor(hex),
        ),
      if (canAddMore)
        Tooltip(
          message: l10n.addColor,
          child: InkWell(
            key: const ValueKey('course-color-save'),
            onTap: _addSavedColor,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
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

/// Small round preview of a saved color, used by the dialogs.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: courseColorFromHex(hex),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({
    required this.initialHex,
    required this.allowDelete,
  });

  final String initialHex;
  final bool allowDelete;

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
    Navigator.of(context).pop(CourseColorSheetResult.saved(hex));
  }

  /// Asks once more before dropping the saved color.
  Future<void> _delete() async {
    final l10n = context.l10n;
    final savedHex =
        normalizeCourseColorHex(widget.initialHex) ?? widget.initialHex;
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
                _ColorDot(hex: savedHex),
                const SizedBox(width: AppSpacing.sm),
                Text(savedHex, style: Theme.of(context).textTheme.titleMedium),
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
    Navigator.of(context).pop(const CourseColorSheetResult.deleted());
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
              widget.allowDelete ? l10n.editColor : l10n.chooseColor,
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
              children: [
                if (widget.allowDelete)
                  TextButton(
                    key: const ValueKey('course-color-delete'),
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.delete),
                  ),
                const Spacer(),
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
