import 'package:flutter/material.dart';
import 'package:mysues/services/local_image_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  bool _liquidGlassEnabled = false;
  bool _splashAnimationEnabled = false;
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.5;

  ThemeMode get themeMode => _themeMode;
  bool get liquidGlassEnabled => _liquidGlassEnabled;
  bool get splashAnimationEnabled => _splashAnimationEnabled;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundOpacity => _backgroundOpacity;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final int? modeIndex = prefs.getInt('theme_mode');
    _liquidGlassEnabled = prefs.getBool('liquid_glass_beta') ?? false;
    _splashAnimationEnabled = prefs.getBool('splash_animation_enabled') ?? false;
    try {
      final backgroundFile = await LocalImageStore.background.load();
      _backgroundImagePath = backgroundFile?.path;
    } catch (_) {
      // Never block startup because the stored image could not be resolved.
      _backgroundImagePath = null;
    }
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
    final file = await LocalImageStore.background.save(sourcePath);
    _backgroundImagePath = file.path;
    notifyListeners();
  }

  Future<void> clearBackgroundImage() async {
    await LocalImageStore.background.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_opacity');
    _backgroundImagePath = null;
    _backgroundOpacity = 0.5;
    notifyListeners();
  }

  /// Self-heals a background image that could not be rendered.
  ///
  /// Called from image error builders. Only the path that is currently stored
  /// is acted on, so a stale error from a previous image cannot wipe a working
  /// background. The in-memory state is cleared first to make sure the caller
  /// stops rebuilding the broken image.
  Future<void> handleBackgroundImageError(String failedPath) async {
    if (_backgroundImagePath == null || _backgroundImagePath != failedPath) {
      return;
    }

    _backgroundImagePath = null;
    notifyListeners();

    try {
      await LocalImageStore.background.clear();
    } catch (_) {
      // Best effort: the background is already gone from the in-memory state.
    }
  }

  /// Drops the cached display settings after `SharedPreferences` were wiped by
  /// "clear all data", so the UI stops pointing at deleted files without a
  /// restart.
  void resetAfterExternalClear() {
    _themeMode = ThemeMode.system;
    _liquidGlassEnabled = false;
    _splashAnimationEnabled = false;
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
