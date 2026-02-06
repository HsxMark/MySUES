import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  String? _fontFamily;

  ThemeMode get themeMode => _themeMode;
  String? get fontFamily => _fontFamily;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final int? modeIndex = prefs.getInt('theme_mode');
    _fontFamily = prefs.getString('app_font_family');
    
    // 0 = System, 1 = Light, 2 = Dark
    switch (modeIndex) {
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
      case 0:
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  Future<void> updateFontFamily(String? family) async {
    final prefs = await SharedPreferences.getInstance();
    if (family == null) {
      await prefs.remove('app_font_family');
    } else {
      await prefs.setString('app_font_family', family);
    }
    _fontFamily = family;
    notifyListeners();
  }

  Future<void> updateThemeMode(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', index);
    
    switch (index) {
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
      case 0:
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}
