import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/course_palette.dart';

/// Remembers the most recently used custom course colors so the color picker
/// can offer them again without re-tuning the sliders.
abstract final class CourseColorStore {
  static const String _recentColorsKey = 'recent_course_colors_v1';

  /// How many custom colors are kept.
  static const int maxRecentColors = 6;

  /// Most recently used custom colors, newest first.
  static Future<List<String>> loadRecentColors() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentColorsKey);
    if (raw == null || raw.isEmpty) return const <String>[];

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
      if (colors.length == maxRecentColors) break;
    }
    return colors;
  }

  /// Records [rawHex] as the newest custom color and returns the updated list.
  static Future<List<String>> addRecentColor(String? rawHex) async {
    final current = await loadRecentColors();
    final hex = normalizeCourseColorHex(rawHex);
    if (hex == null) return current;

    final updated = <String>[
      hex,
      ...current.where((existing) => existing != hex),
    ].take(maxRecentColors).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentColorsKey, jsonEncode(updated));
    return updated;
  }
}
