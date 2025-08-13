import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_id_generator.dart';
import '../../utils/app_logger.dart';

/// Service to migrate existing companies to secure company IDs
class CompanyMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate a single company to secure ID structure
  static Future<Map<String, dynamic>> migrateCompany(
      String oldCompanyId) async {
    try {
      AppLogger.info('Starting migration for company: $oldCompanyId');

      // 1. Get the old company document
      final oldCompanyDoc =
          await _firestore.collection('companies').doc(oldCompanyId).get();

      if (!oldCompanyDoc.exists) {
        throw Exception('Company $oldCompanyId not found');
      }

      final oldCompanyData = oldCompanyDoc.data()!;

      // 2. Generate or reuse secure company ID
      String? newCompanyId;
      if (oldCompanyData.containsKey('secureId')) {
        newCompanyId = oldCompanyData['secureId'] as String;
      } else {
        newCompanyId = CompanyIdGenerator.generateSecureCompanyId(oldCompanyId);
      }
      AppLogger.debug('Using company ID: $newCompanyId');

      // 3. Create new company document with secure ID
      await _firestore.collection('companies').doc(newCompanyId).set({
        ...oldCompanyData,
        'originalId': oldCompanyId, // Keep reference to original
        'migratedAt': FieldValue.serverTimestamp(),
        'secureId': newCompanyId,
      });

      // 4. Migrate all users in this company
      final usersSnapshot = await _firestore
          .collection('companies')
          .doc(oldCompanyId)
          .collection('users')
          .get();

      final migratedUsers = <String>[];

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        // Create user access document in userCompany collection
        await _firestore.collection('userCompany').doc(userId).set({
          'email': userData['email'] ?? '',
          'companyId': newCompanyId,
        });

        // Copy user data to new company structure
        await _firestore
            .collection('companies')
            .doc(newCompanyId)
            .collection('users')
            .doc(userId)
            .set({
          ...userData,
          'migratedAt': FieldValue.serverTimestamp(),
        });

        // --- MIGRATE all_logs ---
        final allLogsSnapshot = await _firestore
            .collection('companies')
            .doc(oldCompanyId)
            .collection('users')
            .doc(userId)
            .collection('all_logs')
            .get();
        for (final logDoc in allLogsSnapshot.docs) {
          await _firestore
              .collection('companies')
              .doc(newCompanyId)
              .collection('users')
              .doc(userId)
              .collection('all_logs')
              .doc(logDoc.id)
              .set(logDoc.data());
        }
        // --- MIGRATE sessions and nested logs ---
        final sessionsSnapshot = await _firestore
            .collection('companies')
            .doc(oldCompanyId)
            .collection('users')
            .doc(userId)
            .collection('sessions')
            .get();
        for (final sessionDoc in sessionsSnapshot.docs) {
          await _firestore
              .collection('companies')
              .doc(newCompanyId)
              .collection('users')
              .doc(userId)
              .collection('sessions')
              .doc(sessionDoc.id)
              .set(sessionDoc.data());
          // Migrate logs in each session
          final logsSnapshot = await _firestore
              .collection('companies')
              .doc(oldCompanyId)
              .collection('users')
              .doc(userId)
              .collection('sessions')
              .doc(sessionDoc.id)
              .collection('logs')
              .get();
          for (final logDoc in logsSnapshot.docs) {
            await _firestore
                .collection('companies')
                .doc(newCompanyId)
                .collection('users')
                .doc(userId)
                .collection('sessions')
                .doc(sessionDoc.id)
                .collection('logs')
                .doc(logDoc.id)
                .set(logDoc.data());
          }
        }

        migratedUsers.add(userId);
      }

      // 5. Copy other company collections (projects, etc.)
      await _migrateCompanyCollections(oldCompanyId, newCompanyId);

      // 6. Create migration record
      await _firestore
          .collection('migrations')
          .doc('company_${oldCompanyId}')
          .set({
        'oldCompanyId': oldCompanyId,
        'newCompanyId': newCompanyId,
        'migratedAt': FieldValue.serverTimestamp(),
        'migratedUsers': migratedUsers,
        'status': 'completed',
      });

      AppLogger.info(
          'Migration completed for company: $oldCompanyId → $newCompanyId');

      return {
        'oldCompanyId': oldCompanyId,
        'newCompanyId': newCompanyId,
        'migratedUsers': migratedUsers.length,
        'status': 'success',
      };
    } catch (e) {
      AppLogger.error('Migration failed for company $oldCompanyId: $e');
      throw Exception('Migration failed: $e');
    }
  }

  /// Migrate all companies in the system
  static Future<List<Map<String, dynamic>>> migrateAllCompanies() async {
    try {
      AppLogger.info('Starting migration of all companies...');

      // Get all existing companies
      final companiesSnapshot = await _firestore.collection('companies').get();

      final results = <Map<String, dynamic>>[];

      for (final companyDoc in companiesSnapshot.docs) {
        final companyId = companyDoc.id;

        // Skip if already migrated (has secureId field)
        final companyData = companyDoc.data();
        if (companyData.containsKey('secureId')) {
          AppLogger.debug('Company $companyId already migrated, skipping...');
          continue;
        }

        try {
          final result = await migrateCompany(companyId);
          results.add(result);

          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          AppLogger.error('Failed to migrate company $companyId: $e');
          results.add({
            'oldCompanyId': companyId,
            'status': 'failed',
            'error': e.toString(),
          });
        }
      }

      AppLogger.info('Migration of all companies completed. Results: $results');
      return results;
    } catch (e) {
      AppLogger.error('Migration of all companies failed: $e');
      throw Exception('Migration failed: $e');
    }
  }

  /// Migrate company collections (projects, etc.)
  static Future<void> _migrateCompanyCollections(
      String oldCompanyId, String newCompanyId) async {
    // List of collections to migrate
    const collectionsToMigrate = ['projects', 'clients'];

    for (final collectionName in collectionsToMigrate) {
      try {
        final collectionSnapshot = await _firestore
            .collection('companies')
            .doc(oldCompanyId)
            .collection(collectionName)
            .get();

        for (final doc in collectionSnapshot.docs) {
          await _firestore
              .collection('companies')
              .doc(newCompanyId)
              .collection(collectionName)
              .doc(doc.id)
              .set({
            ...doc.data(),
            'migratedAt': FieldValue.serverTimestamp(),
          });
        }

        AppLogger.debug(
            'Migrated $collectionName collection: ${collectionSnapshot.docs.length} documents');
      } catch (e) {
        AppLogger.error('Failed to migrate $collectionName collection: $e');
      }
    }
  }

  /// Check migration status for a company
  static Future<Map<String, dynamic>?> getMigrationStatus(
      String companyId) async {
    try {
      final migrationDoc = await _firestore
          .collection('migrations')
          .doc('company_$companyId')
          .get();

      if (migrationDoc.exists) {
        return migrationDoc.data();
      }

      return null;
    } catch (e) {
      AppLogger.error('Error checking migration status: $e');
      return null;
    }
  }

  /// Rollback migration (delete new structure, keep old)
  static Future<void> rollbackMigration(String oldCompanyId) async {
    try {
      final migrationDoc = await _firestore
          .collection('migrations')
          .doc('company_$oldCompanyId')
          .get();

      if (!migrationDoc.exists) {
        throw Exception('No migration record found for $oldCompanyId');
      }

      final migrationData = migrationDoc.data()!;
      final newCompanyId = migrationData['newCompanyId'];

      // Delete new company document
      await _firestore.collection('companies').doc(newCompanyId).delete();

      // Delete user access documents
      final migratedUsers =
          List<String>.from(migrationData['migratedUsers'] ?? []);
      for (final userId in migratedUsers) {
        await _firestore.collection('users').doc(userId).delete();
      }

      // Delete migration record
      await _firestore
          .collection('migrations')
          .doc('company_$oldCompanyId')
          .delete();

      AppLogger.info('Rollback completed for company: $oldCompanyId');
    } catch (e) {
      AppLogger.error('Rollback failed for company $oldCompanyId: $e');
      throw Exception('Rollback failed: $e');
    }
  }
}
