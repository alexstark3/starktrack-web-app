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

    debugPrint('[ThemeProvider] RAW loaded theme: $theme'); // NEW debug print

    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _language = sp.getString(_kLangKey) ?? 'EN';

    _ready = true;
    notifyListeners();
    debugPrint('[ThemeProvider] Loaded theme: $_themeMode, lang: $_language');
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final value = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _save(_kThemeKey, value);
    debugPrint('[ThemeProvider] Saved theme: $value');
    notifyListeners();
    debugPrint('[ThemeProvider] Toggled theme: $_themeMode');
  }

  Future<void> setLanguage(String lang) async {
    if (lang == _language) return;
    _language = lang;
    await _save(_kLangKey, lang);
    notifyListeners();
    debugPrint('[ThemeProvider] Language set: $_language');
  }

  Future<void> _save(String key, String value) async {
    final sp = await SharedPreferences.getInstance();
    final ok = await sp.setString(key, value);
    debugPrint('[ThemeProvider] _save: key=$key, value=$value, success=$ok'); // <-- see if this is true or false!
  }
}
