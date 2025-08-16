import 'package:flutter/services.dart';
import '../../utils/app_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AdminVersionService {
  static const String _versionFile = 'assets/admin_version.txt';

  /// Get the admin-specific version
  /// This reads from a separate version file or falls back to package info
  static Future<String> getAdminVersion() async {
    try {
      // Try to read from admin version file first
      final versionData = await rootBundle.loadString(_versionFile);
      final lines = versionData.split('\n');
      for (final line in lines) {
        if (line.startsWith('Version:')) {
          return line.replaceFirst('Version:', '').trim();
        }
      }
    } catch (e) {
      // If version file doesn't exist, fall back to package info
      AppLogger.warn('Admin version file not found, using package info: $e');
    }

    // Fallback: use package info with admin format
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final mainVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // Format: 1.1.1.152 (main version + build number as fourth segment)
      return '$mainVersion.$buildNumber';
    } catch (e) {
      AppLogger.error('Error getting package info: $e');
      return '1.1.1.0'; // Fallback version
    }
  }
}
