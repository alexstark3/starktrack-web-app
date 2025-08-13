import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_logger.dart';

class CompanyModuleService {
  static const String _companiesCollection = 'companies';

  /// Get all available modules
  static List<String> getAvailableModules() {
    return [
      'time_tracker',
      'admin',
      'team',
      'projects',
      'clients',
      'history',
    ];
  }

  /// Get module display name
  static String getModuleDisplayName(String module) {
    switch (module) {
      case 'time_tracker':
        return 'Time Tracker';
      case 'admin':
        return 'Admin Panel';
      case 'team':
        return 'Team Management';
      case 'projects':
        return 'Projects';
      case 'clients':
        return 'Clients';
      case 'history':
        return 'History';
      default:
        return module;
    }
  }

  /// Get module description
  static String getModuleDescription(String module) {
    switch (module) {
      case 'time_tracker':
        return 'Track time and manage work sessions';
      case 'admin':
        return 'User management and company settings';
      case 'team':
        return 'Manage team members and roles';
      case 'projects':
        return 'Create and manage projects';
      case 'clients':
        return 'Manage client relationships';
      case 'history':
        return 'View time tracking history and reports';
      default:
        return '';
    }
  }

  /// Update company modules
  static Future<bool> updateCompanyModules(
      String companyId, List<String> modules) async {
    try {
      await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .update({
        'modules': modules,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error updating company modules: $e');
      return false;
    }
  }

  /// Get company modules
  static Future<List<String>> getCompanyModules(String companyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final modulesData = data['modules'];

        if (modulesData == null) return [];

        if (modulesData is List) {
          return List<String>.from(modulesData);
        } else if (modulesData is Map) {
          // Convert Map to List (keys are module names)
          return modulesData.keys.cast<String>().toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting company modules: $e');
      return [];
    }
  }

  /// Check if company has specific module
  static Future<bool> companyHasModule(String companyId, String module) async {
    final modules = await getCompanyModules(companyId);
    return modules.contains(module);
  }

  /// Add module to company
  static Future<bool> addModuleToCompany(
      String companyId, String module) async {
    try {
      final currentModules = await getCompanyModules(companyId);
      if (!currentModules.contains(module)) {
        currentModules.add(module);
        return await updateCompanyModules(companyId, currentModules);
      }
      return true; // Module already exists
    } catch (e) {
      AppLogger.error('Error adding module to company: $e');
      return false;
    }
  }

  /// Remove module from company
  static Future<bool> removeModuleFromCompany(
      String companyId, String module) async {
    try {
      final currentModules = await getCompanyModules(companyId);
      currentModules.remove(module);
      return await updateCompanyModules(companyId, currentModules);
    } catch (e) {
      AppLogger.error('Error removing module from company: $e');
      return false;
    }
  }

  /// Get all companies with their modules
  static Future<List<Map<String, dynamic>>> getAllCompaniesWithModules() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Handle modules field - could be Map or List
        List<String> modules = [];
        final modulesData = data['modules'];
        if (modulesData != null) {
          if (modulesData is List) {
            modules = List<String>.from(modulesData);
          } else if (modulesData is Map) {
            // Convert Map to List (keys are module names)
            modules = modulesData.keys.cast<String>().toList();
          }
        }

        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Company',
          'email': data['email'] ?? '',
          'modules': modules,
          'active': data['active'] ?? true,
          'userLimit': data['userLimit'] ?? 10,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting companies with modules: $e');
      return [];
    }
  }

  /// Update company user limit
  static Future<bool> updateCompanyUserLimit(
      String companyId, int userLimit) async {
    try {
      await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .update({
        'userLimit': userLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error updating company user limit: $e');
      return false;
    }
  }

  /// Get company user limit
  static Future<int> getCompanyUserLimit(String companyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['userLimit'] ?? 10;
      }
      return 10; // Default limit
    } catch (e) {
      AppLogger.error('Error getting company user limit: $e');
      return 10;
    }
  }

  /// Check if company can add more users
  static Future<bool> canAddUser(String companyId) async {
    try {
      final userLimit = await getCompanyUserLimit(companyId);
      final userCount = await getCompanyUserCount(companyId);
      return userCount < userLimit;
    } catch (e) {
      AppLogger.error('Error checking if company can add user: $e');
      return false;
    }
  }

  /// Get company user count
  static Future<int> getCompanyUserCount(String companyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['userCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error getting company user count: $e');
      return 0;
    }
  }

  /// Update company user count
  static Future<bool> updateCompanyUserCount(
      String companyId, int userCount) async {
    try {
      await FirebaseFirestore.instance
          .collection(_companiesCollection)
          .doc(companyId)
          .update({
        'userCount': userCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error updating company user count: $e');
      return false;
    }
  }

  /// Decrement company user count (when removing a user)
  static Future<bool> decrementUserCount(String companyId) async {
    try {
      final currentCount = await getCompanyUserCount(companyId);
      final newCount = currentCount > 0 ? currentCount - 1 : 0;
      return await updateCompanyUserCount(companyId, newCount);
    } catch (e) {
      AppLogger.error('Error decrementing user count: $e');
      return false;
    }
  }

  /// Increment company user count (when adding a user)
  static Future<bool> incrementUserCount(String companyId) async {
    try {
      final currentCount = await getCompanyUserCount(companyId);
      return await updateCompanyUserCount(companyId, currentCount + 1);
    } catch (e) {
      AppLogger.error('Error incrementing user count: $e');
      return false;
    }
  }
}
