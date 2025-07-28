import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;

// Production-ready storage that works reliably online

class CalendarStorage {
  static const String _startWeekdayKey = 'calendar_start_weekday';
  static const String _showWeekNumbersKey = 'calendar_show_week_numbers';

  // Use a consistent key that works across different ports
  static const String _localStorageKey = 'starktrack_calendar_settings';

  // Save settings with production-ready reliability
  static Future<void> saveSettings(
      int startWeekday, bool showWeekNumbers) async {
    bool localStorageSuccess = false;
    bool cookieSuccess = false;
    bool sharedPrefsSuccess = false;

    // Primary method: localStorage (most reliable for web)
    try {
      _saveToLocalStorage(startWeekday, showWeekNumbers);
      localStorageSuccess = true;
      print('Settings saved via localStorage (primary)');
    } catch (e) {
      print('localStorage failed: $e');
    }

    // Backup method: Cookies (works across all browsers)
    try {
      _saveToCookies(startWeekday, showWeekNumbers);
      cookieSuccess = true;
      print('Settings saved via cookies (backup)');
    } catch (e) {
      print('Cookies failed: $e');
    }

    // Fallback method: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_startWeekdayKey, startWeekday);
      await prefs.setBool(_showWeekNumbersKey, showWeekNumbers);
      sharedPrefsSuccess = true;
      print('Settings saved via SharedPreferences (fallback)');
    } catch (e) {
      print('SharedPreferences failed: $e');
    }

    if (localStorageSuccess || cookieSuccess || sharedPrefsSuccess) {
      print(
          'Settings saved successfully via ${localStorageSuccess ? "localStorage" : ""}${localStorageSuccess && cookieSuccess ? " and " : ""}${cookieSuccess ? "cookies" : ""}${(localStorageSuccess || cookieSuccess) && sharedPrefsSuccess ? " and " : ""}${sharedPrefsSuccess ? "SharedPreferences" : ""}');
    } else {
      print('Failed to save settings via any method');
    }
  }

  // Load settings with production-ready reliability
  static Future<Map<String, dynamic>> loadSettings() async {
    // Primary method: localStorage (most reliable for web)
    try {
      final settings = _loadFromLocalStorage();
      if (settings != null) {
        print('Settings loaded via localStorage (primary): $settings');
        return settings;
      }
    } catch (e) {
      print('localStorage failed: $e');
    }

    // Backup method: Cookies
    try {
      final settings = _loadFromCookies();
      if (settings != null) {
        print('Settings loaded via cookies (backup): $settings');
        return settings;
      }
    } catch (e) {
      print('Cookies failed: $e');
    }

    // Fallback method: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final startWeekday = prefs.getInt(_startWeekdayKey);
      final showWeekNumbers = prefs.getBool(_showWeekNumbersKey);

      if (startWeekday != null && showWeekNumbers != null) {
        print(
            'Settings loaded via SharedPreferences (fallback): startWeekday=$startWeekday, showWeekNumbers=$showWeekNumbers');
        return {
          'startWeekday': startWeekday,
          'showWeekNumbers': showWeekNumbers,
        };
      }
    } catch (e) {
      print('SharedPreferences failed: $e');
    }

    print('No saved settings found, using defaults');
    return {};
  }

  // Web-specific localStorage methods
  static void _saveToLocalStorage(int startWeekday, bool showWeekNumbers) {
    try {
      final settings = {
        'startWeekday': startWeekday,
        'showWeekNumbers': showWeekNumbers,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0', // Add version for future compatibility
      };
      final jsonData = jsonEncode(settings);
      html.window.localStorage[_localStorageKey] = jsonData;
      print('localStorage saved with key "$_localStorageKey": $jsonData');

      // Verify the save
      final savedData = html.window.localStorage[_localStorageKey];
      print('localStorage verification: $savedData');
    } catch (e) {
      throw Exception('Failed to save to localStorage: $e');
    }
  }

  static Map<String, dynamic>? _loadFromLocalStorage() {
    try {
      final data = html.window.localStorage[_localStorageKey];
      print('localStorage raw data with key "$_localStorageKey": $data');
      if (data != null) {
        final settings = jsonDecode(data) as Map<String, dynamic>;
        print('localStorage parsed settings: $settings');

        // Check if we have the required fields
        if (settings.containsKey('startWeekday') &&
            settings.containsKey('showWeekNumbers')) {
          return {
            'startWeekday': settings['startWeekday'] as int,
            'showWeekNumbers': settings['showWeekNumbers'] as bool,
          };
        } else {
          print('localStorage data missing required fields');
        }
      }

      // Try the old key for backward compatibility
      final oldData = html.window.localStorage['calendar_settings'];
      if (oldData != null) {
        print('Found old localStorage data, migrating...');
        try {
          final oldSettings = jsonDecode(oldData) as Map<String, dynamic>;
          if (oldSettings.containsKey('startWeekday') &&
              oldSettings.containsKey('showWeekNumbers')) {
            // Migrate to new format
            _saveToLocalStorage(
              oldSettings['startWeekday'] as int,
              oldSettings['showWeekNumbers'] as bool,
            );
            // Remove old data
            html.window.localStorage.remove('calendar_settings');
            print('Migrated old data to new format');
            return {
              'startWeekday': oldSettings['startWeekday'] as int,
              'showWeekNumbers': oldSettings['showWeekNumbers'] as bool,
            };
          }
        } catch (e) {
          print('Error migrating old data: $e');
        }
      }
    } catch (e) {
      print('Error loading from localStorage: $e');
    }
    return null;
  }

  // Cookie methods for production reliability
  static void _saveToCookies(int startWeekday, bool showWeekNumbers) {
    try {
      final settings = {
        'startWeekday': startWeekday,
        'showWeekNumbers': showWeekNumbers,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      final jsonData = jsonEncode(settings);

      // Set cookie with long expiration (1 year)
      final expires = DateTime.now().add(const Duration(days: 365));
      final cookieValue =
          'starktrack_calendar_settings=$jsonData; expires=${expires.toUtc().toIso8601String()}; path=/; SameSite=Lax';

      html.document.cookie = cookieValue;
      print('Settings saved via cookies: $jsonData');
    } catch (e) {
      throw Exception('Failed to save to cookies: $e');
    }
  }

  static Map<String, dynamic>? _loadFromCookies() {
    try {
      final cookieString = html.document.cookie;
      if (cookieString == null || cookieString.isEmpty) return null;

      final cookies = cookieString.split(';');
      for (final cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts.length == 2 && parts[0] == 'starktrack_calendar_settings') {
          final data = parts[1];
          print('Cookie raw data: $data');

          final settings = jsonDecode(data) as Map<String, dynamic>;
          print('Cookie parsed settings: $settings');

          if (settings.containsKey('startWeekday') &&
              settings.containsKey('showWeekNumbers')) {
            return {
              'startWeekday': settings['startWeekday'] as int,
              'showWeekNumbers': settings['showWeekNumbers'] as bool,
            };
          }
        }
      }
    } catch (e) {
      print('Error loading from cookies: $e');
    }
    return null;
  }
}
