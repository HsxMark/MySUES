import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, zhHans, english }

class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService _instance = LocaleService._();
  factory LocaleService() => _instance;

  static const _preferenceKey = 'app_language';
  AppLanguage _language = AppLanguage.system;

  AppLanguage get language => _language;

  Locale? get localeOverride => switch (_language) {
    AppLanguage.system => null,
    AppLanguage.zhHans => const Locale('zh'),
    AppLanguage.english => const Locale('en'),
  };

  Locale get effectiveLocale =>
      resolveLocale(localeOverride ?? PlatformDispatcher.instance.locale);

  String get effectiveLanguageCode => effectiveLocale.languageCode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _language = switch (prefs.getString(_preferenceKey)) {
      'zh' => AppLanguage.zhHans,
      'en' => AppLanguage.english,
      _ => AppLanguage.system,
    };
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, switch (language) {
      AppLanguage.system => 'system',
      AppLanguage.zhHans => 'zh',
      AppLanguage.english => 'en',
    });
    notifyListeners();
  }

  static Locale resolveLocale(Locale locale) =>
      locale.languageCode.toLowerCase() == 'zh'
      ? const Locale('zh')
      : const Locale('en');
}
