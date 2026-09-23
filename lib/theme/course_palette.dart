import 'package:flutter/material.dart';

/// Course color palettes shared by the course editor and the academic import.
///
/// Colors are persisted on `Course.color` as `#RRGGBB` hex strings. Keep
/// [CoursePalette.classic] in sync with the import order in
/// `FetchCourseService._generateColor`, so a color picked by hand can always
/// match an auto-imported one.
abstract final class CoursePalette {
  /// The 10 Material colors that older builds and the academic import use.
  static const List<Color> classic = <Color>[
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF009688),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  /// 12 muted, mid-tone Morandi colors. They stay close in luminance to the
  /// classic palette so the default white course text keeps working.
  static const List<Color> morandi = <Color>[
    Color(0xFF7E93A8), // 雾霾蓝
    Color(0xFF6F8F86), // 松青
    Color(0xFF8A9A7B), // 灰橄榄
    Color(0xFFA08C7A), // 灰驼
    Color(0xFFB08A87), // 豆沙
    Color(0xFF9A8AA0), // 灰紫
    Color(0xFFC08A7D), // 陶土
    Color(0xFF7C9AA0), // 灰湖蓝
    Color(0xFF8C9463), // 橄榄黄
    Color(0xFFA8707A), // 莓红
    Color(0xFF6E7B8B), // 石板蓝
    Color(0xFFA9956F), // 灰卡其
  ];

  /// Every preset color, used when checking whether a custom color is new.
  static const List<Color> all = <Color>[...classic, ...morandi];

  /// [classic] as the `#RRGGBB` strings stored on `Course.color`.
  static List<String> get classicHexes =>
      classic.map(courseColorToHex).toList();

  /// [morandi] as the `#RRGGBB` strings stored on `Course.color`.
  static List<String> get morandiHexes =>
      morandi.map(courseColorToHex).toList();

  /// The color a newly created course starts with.
  static String get defaultHex => courseColorToHex(classic.first);
}

/// Formats [color] as the `#RRGGBB` string stored on `Course.color`.
String courseColorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Parses `#RRGGBB`, `RRGGBB`, `#AARRGGBB` or `AARRGGBB`. Returns null when
/// the input is not a valid hex color.
Color? courseColorFromHex(String? raw) {
  if (raw == null) return null;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;

  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

/// Returns the canonical uppercase `#RRGGBB` form of [raw], or null when the
/// value cannot be parsed.
String? normalizeCourseColorHex(String? raw) {
  final color = courseColorFromHex(raw);
  return color == null ? null : courseColorToHex(color);
}
