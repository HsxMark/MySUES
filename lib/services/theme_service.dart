import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  String? _fontFamily;
  bool _liquidGlassEnabled = false;
  bool _splashAnimationEnabled = true;
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.5;

  ThemeMode get themeMode => _themeMode;
  String? get fontFamily => _fontFamily;
  bool get liquidGlassEnabled => _liquidGlassEnabled;
  bool get splashAnimationEnabled => _splashAnimationEnabled;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundOpacity => _backgroundOpacity;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final int? modeIndex = prefs.getInt('theme_mode');
    _fontFamily = prefs.getString('app_font_family');
    _liquidGlassEnabled = prefs.getBool('liquid_glass_beta') ?? false;
    _splashAnimationEnabled = prefs.getBool('splash_animation_enabled') ?? true;
    _backgroundImagePath = prefs.getString('background_image_path');
    _backgroundOpacity = prefs.getDouble('background_opacity') ?? 0.5;
    
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

  Future<void> updateLiquidGlass(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liquid_glass_beta', value);
    _liquidGlassEnabled = value;
    notifyListeners();
  }

  Future<void> updateSplashAnimation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('splash_animation_enabled', value);
    _splashAnimationEnabled = value;
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

  Future<void> updateBackgroundImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.substring(sourcePath.lastIndexOf('.')) : '';
    final destPath = '${dir.path}/background_image$ext';
    await File(sourcePath).copy(destPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image_path', destPath);
    _backgroundImagePath = destPath;
    notifyListeners();
  }

  Future<void> clearBackgroundImage() async {
    if (_backgroundImagePath != null) {
      final file = File(_backgroundImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image_path');
    await prefs.remove('background_opacity');
    _backgroundImagePath = null;
    _backgroundOpacity = 0.5;
    notifyListeners();
  }

  Future<void> updateBackgroundOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_opacity', opacity);
    _backgroundOpacity = opacity;
    notifyListeners();
  }
}
