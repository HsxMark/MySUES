import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/course_palette.dart';

/// Remembers the course colors the user saved under "My Colors" so the picker
/// can offer them again without re-tuning the sliders.
abstract final class CourseColorStore {
  static const String _savedColorsKey = 'saved_course_colors_v1';

  /// Key used by older builds that only remembered the last used colors.
  static const String _legacyRecentColorsKey = 'recent_course_colors_v1';

  /// How many colors the user can keep in "My Colors".
  static const int maxSavedColors = 12;

  /// Saved custom colors, newest first.
  static Future<List<String>> loadSavedColors() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedColorsKey);
    if (raw == null || raw.isEmpty) return _migrateLegacyColors(prefs);
    return _decodeColors(raw);
  }

  /// Stores [rawHex] as the newest saved color and returns the updated list.
  ///
  /// Invalid values, colors that are already saved and colors added beyond
  /// [maxSavedColors] leave the list untouched.
  static Future<List<String>> addSavedColor(String? rawHex) async {
    final colors = await loadSavedColors();
    final hex = normalizeCourseColorHex(rawHex);
    if (hex == null || colors.contains(hex)) return colors;
    if (colors.length >= maxSavedColors) return colors;

    final updated = <String>[hex, ...colors];
    await _writeColors(updated);
    return updated;
  }

  /// Removes [rawHex] from the saved list and returns the updated list.
  static Future<List<String>> removeSavedColor(String? rawHex) async {
    final colors = await loadSavedColors();
    final hex = normalizeCourseColorHex(rawHex);
    if (hex == null || !colors.contains(hex)) return colors;

    final updated = colors.where((existing) => existing != hex).toList();
    await _writeColors(updated);
    return updated;
  }

  /// Replaces [rawOldHex] with [rawNewHex] without changing its position.
  ///
  /// The list is returned untouched when the old color is not saved, when the
  /// new color is invalid, or when the new color is already saved elsewhere.
  static Future<List<String>> replaceSavedColor(
    String? rawOldHex,
    String? rawNewHex,
  ) async {
    final colors = await loadSavedColors();
    final oldHex = normalizeCourseColorHex(rawOldHex);
    final newHex = normalizeCourseColorHex(rawNewHex);
    if (oldHex == null || newHex == null) return colors;
    if (oldHex == newHex) return colors;

    final index = colors.indexOf(oldHex);
    if (index == -1 || colors.contains(newHex)) return colors;

    final updated = [...colors]..[index] = newHex;
    await _writeColors(updated);
    return updated;
  }

  /// Forgets every saved color.
  static Future<void> clearSavedColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedColorsKey);
  }

  /// One time move of the previously auto-recorded colors into "My Colors".
  static Future<List<String>> _migrateLegacyColors(
    SharedPreferences prefs,
  ) async {
    final legacy = prefs.getString(_legacyRecentColorsKey);
    if (legacy == null || legacy.isEmpty) return const <String>[];

    final colors = _decodeColors(legacy);
    await prefs.remove(_legacyRecentColorsKey);
    if (colors.isNotEmpty) {
      await prefs.setString(_savedColorsKey, jsonEncode(colors));
    }
    return colors;
  }

  static List<String> _decodeColors(String raw) {
    final List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const <String>[];
      decoded = value;
    } catch (_) {
      return const <String>[];
    }

    final colors = <String>[];
    for (final item in decoded) {
      final hex = normalizeCourseColorHex(item is String ? item : null);
      if (hex == null || colors.contains(hex)) continue;
      colors.add(hex);
      if (colors.length == maxSavedColors) break;
    }
    return colors;
  }

  static Future<void> _writeColors(List<String> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedColorsKey, jsonEncode(colors));
  }
}
