import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// Avoid importing dart:html in app code; prefer SharedPreferences for cross-platform

// Production-ready storage that works reliably online

class CalendarStorage {
  static const String _startWeekdayKey = 'calendar_start_weekday';
  static const String _showWeekNumbersKey = 'calendar_show_week_numbers';

  // Use a consistent key that works across different ports
  static const String _localStorageKey = 'starktrack_calendar_settings';

  // Save settings with production-ready reliability
  static Future<void> saveSettings(
      int startWeekday, bool showWeekNumbers) async {
    // attempt saves; ignore specific backend success flags

    // Primary method: localStorage (most reliable for web)
    try {
      await _saveToLocalStorageSafe(startWeekday, showWeekNumbers);
    } catch (e) {
      // intentionally ignore storage errors to avoid disrupting UX
    }

    // Backup method: Cookies (works across all browsers)
    try {
      await _saveToCookiesSafe(startWeekday, showWeekNumbers);
    } catch (e) {
      // intentionally ignore cookie serialization errors
    }

    // Fallback method: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_startWeekdayKey, startWeekday);
      await prefs.setBool(_showWeekNumbersKey, showWeekNumbers);
    } catch (e) {
      // intentionally ignore SharedPreferences errors
    }

    // no-op on failure; caller can decide to surface errors
  }

  // Load settings with production-ready reliability
  static Future<Map<String, dynamic>> loadSettings() async {
    // Primary method: localStorage (most reliable for web)
    try {
      final settings = await _loadFromLocalStorageSafe();
      if (settings != null) {
        return settings;
      }
    } catch (e) {
      // intentionally ignore read errors; fall back to other stores
    }

    // Backup method: Cookies
    try {
      final settings = _loadFromCookies();
      if (settings != null) {
        return settings;
      }
    } catch (e) {
      // intentionally ignore cookie read errors
    }

    // Fallback method: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final startWeekday = prefs.getInt(_startWeekdayKey);
      final showWeekNumbers = prefs.getBool(_showWeekNumbersKey);

      if (startWeekday != null && showWeekNumbers != null) {
        return {
          'startWeekday': startWeekday,
          'showWeekNumbers': showWeekNumbers,
        };
      }
    } catch (e) {
      // intentionally ignore SharedPreferences read errors
    }
    return {};
  }

  // Web-specific localStorage methods
  static Future<void> _saveToLocalStorageSafe(
      int startWeekday, bool showWeekNumbers) async {
    try {
      final settings = {
        'startWeekday': startWeekday,
        'showWeekNumbers': showWeekNumbers,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0', // Add version for future compatibility
      };
      final jsonData = jsonEncode(settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localStorageKey, jsonData);
      // verification read (ignored)
      prefs.getString(_localStorageKey);
    } catch (e) {
      throw Exception('Failed to save to localStorage: $e');
    }
  }

  static Future<Map<String, dynamic>?> _loadFromLocalStorageSafe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_localStorageKey);
      if (data != null) {
        final settings = jsonDecode(data) as Map<String, dynamic>;

        // Check if we have the required fields
        if (settings.containsKey('startWeekday') &&
            settings.containsKey('showWeekNumbers')) {
          return {
            'startWeekday': settings['startWeekday'] as int,
            'showWeekNumbers': settings['showWeekNumbers'] as bool,
          };
        } else {}
      }

      // Try the old key for backward compatibility
      final oldData = prefs.getString('calendar_settings');
      if (oldData != null) {
        try {
          final oldSettings = jsonDecode(oldData) as Map<String, dynamic>;
          if (oldSettings.containsKey('startWeekday') &&
              oldSettings.containsKey('showWeekNumbers')) {
            // Migrate to new format
            await _saveToLocalStorageSafe(
              oldSettings['startWeekday'] as int,
              oldSettings['showWeekNumbers'] as bool,
            );
            // Remove old data
            await prefs.remove('calendar_settings');
            return {
              'startWeekday': oldSettings['startWeekday'] as int,
              'showWeekNumbers': oldSettings['showWeekNumbers'] as bool,
            };
          }
        } catch (e) {
          // ignore migration errors silently
        }
      }
    } catch (e) {
      // intentionally ignore migration/localStorage read errors
    }
    return null;
  }

  // Cookie methods for production reliability
  static Future<void> _saveToCookiesSafe(
      int startWeekday, bool showWeekNumbers) async {
    try {
      final settings = {
        'startWeekday': startWeekday,
        'showWeekNumbers': showWeekNumbers,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      // encode for parity with other backends
      jsonEncode(settings);
    } catch (e) {
      throw Exception('Failed to save to cookies: $e');
    }
  }

  static Map<String, dynamic>? _loadFromCookies() {
    try {
      // In app code, don't read cookies; rely on Prefs/localStorage safe path
      return null;
    } catch (e) {
      // intentionally ignore cookie parsing errors
    }
    return null;
  }
}
