import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Utility class for managing browser login data persistence
class BrowserPersistence {
  // Keys for regular user login
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  // Keys for super admin login
  static const String _superAdminRememberMeKey = 'super_admin_remember_me';
  static const String _superAdminSavedEmailKey = 'super_admin_saved_email';

  /// Save email for regular user login persistence
  static Future<void> saveUserEmail(String email, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);

      if (rememberMe && email.isNotEmpty) {
        await prefs.setString(_savedEmailKey, email);
      } else {
        await prefs.remove(_savedEmailKey);
      }
    } catch (e) {
      AppLogger.error('Error saving user email: $e');
    }
  }

  /// Load saved email for regular user login
  static Future<String?> loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (rememberMe) {
        return prefs.getString(_savedEmailKey);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error loading user email: $e');
      return null;
    }
  }

  /// Get remember me preference for regular user login
  static Future<bool> getUserRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      AppLogger.error('Error loading user remember me preference: $e');
      return false;
    }
  }

  /// Save email for super admin login persistence
  static Future<void> saveSuperAdminEmail(String email, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_superAdminRememberMeKey, rememberMe);

      if (rememberMe && email.isNotEmpty) {
        await prefs.setString(_superAdminSavedEmailKey, email);
      } else {
        await prefs.remove(_superAdminSavedEmailKey);
      }
    } catch (e) {
      AppLogger.error('Error saving super admin email: $e');
    }
  }

  /// Load saved email for super admin login
  static Future<String?> loadSuperAdminEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_superAdminRememberMeKey) ?? false;

      if (rememberMe) {
        return prefs.getString(_superAdminSavedEmailKey);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error loading super admin email: $e');
      return null;
    }
  }

  /// Get remember me preference for super admin login
  static Future<bool> getSuperAdminRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_superAdminRememberMeKey) ?? false;
    } catch (e) {
      AppLogger.error('Error loading super admin remember me preference: $e');
      return false;
    }
  }

  /// Clear all saved login data
  static Future<void> clearAllLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_superAdminRememberMeKey);
      await prefs.remove(_superAdminSavedEmailKey);
    } catch (e) {
      AppLogger.error('Error clearing login data: $e');
    }
  }

  /// Clear only user login data
  static Future<void> clearUserLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_savedEmailKey);
    } catch (e) {
      AppLogger.error('Error clearing user login data: $e');
    }
  }

  /// Clear only super admin login data
  static Future<void> clearSuperAdminLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_superAdminRememberMeKey);
      await prefs.remove(_superAdminSavedEmailKey);
    } catch (e) {
      AppLogger.error('Error clearing super admin login data: $e');
    }
  }
}
