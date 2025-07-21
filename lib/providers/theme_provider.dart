import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadPrefs();
  }

  bool get isReady => _ready;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;

  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'EN';
  bool _ready = false;

  static const _kThemeKey = 'theme_mode';
  static const _kLangKey = 'language';

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final theme = sp.getString(_kThemeKey);

    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _language = sp.getString(_kLangKey) ?? 'EN';

    _ready = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final value = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _save(_kThemeKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (lang == _language) return;
    _language = lang;
    await _save(_kLangKey, lang);
    notifyListeners();
  }

  Future<void> _save(String key, String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, value);
  }
}
