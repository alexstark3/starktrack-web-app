import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FirestoreBackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recursively convert Firestore Timestamps to ISO strings
  static dynamic convertTimestamps(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, convertTimestamps(v)));
    } else if (value is List) {
      return value.map(convertTimestamps).toList();
    } else if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else {
      return value;
    }
  }

  /// Recursively convert ISO strings back to Timestamp (for restore)
  static dynamic convertIsoStringsToTimestamps(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, convertIsoStringsToTimestamps(v)));
    } else if (value is List) {
      return value.map(convertIsoStringsToTimestamps).toList();
    } else if (value is String && _isIso8601(value)) {
      try {
        return Timestamp.fromDate(DateTime.parse(value));
      } catch (_) {
        return value;
      }
    } else {
      return value;
    }
  }

  static bool _isIso8601(String s) {
    // Simple check for ISO8601 format
    return RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(s);
  }

  /// Recursively fetches all companies and their subcollections
  static Future<Map<String, dynamic>> backupAllCompaniesWithSubcollections() async {
    final companiesBackup = <String, dynamic>{};
    final companiesSnapshot = await _firestore.collection('companies').get();
    for (final companyDoc in companiesSnapshot.docs) {
      final companyId = companyDoc.id;
      final companyData = companyDoc.data();
      final companyMap = <String, dynamic>{
        'companyData': companyData,
      };
      // Backup subcollections
      companyMap['users'] = await _backupSubcollection('companies/$companyId/users', nested: true);
      companyMap['projects'] = await _backupSubcollection('companies/$companyId/projects');
      companyMap['clients'] = await _backupSubcollection('companies/$companyId/clients');
      // Add more subcollections if needed
      companiesBackup[companyId] = companyMap;
    }
    return companiesBackup;
  }

  static Future<List<Map<String, dynamic>>> _backupSubcollection(String path, {bool nested = false}) async {
    final docs = await _firestore.collection(path).get();
    final result = <Map<String, dynamic>>[];
    for (final doc in docs.docs) {
      final docMap = {'id': doc.id, ...doc.data()};
      if (nested) {
        // Always include sessions and all_logs, even if empty
        final sessions = await _backupSubcollection('$path/${doc.id}/sessions', nested: true);
        final allLogs = await _backupSubcollection('$path/${doc.id}/all_logs');
        docMap['sessions'] = sessions;
        docMap['all_logs'] = allLogs;
        for (final session in sessions) {
          final sessionId = session['id'];
          session['logs'] = await _backupSubcollection('$path/${doc.id}/sessions/$sessionId/logs');
        }
      }
      result.add(docMap);
    }
    // If no docs, but nested, return a dummy with empty sessions/all_logs? No, just return empty list.
    return result;
  }

  /// Returns a JSON string for the backup
  static Future<String> backupAllCompaniesAsJson() async {
    final backup = await backupAllCompaniesWithSubcollections();
    final jsonReady = convertTimestamps(backup);
    return jsonEncode(jsonReady);
  }

  /// Restores all companies and their subcollections from a JSON string
  static Future<void> restoreFromJson(String json) async {
    final Map<String, dynamic> backup = jsonDecode(json);
    for (final companyId in backup.keys) {
      final companyMap = backup[companyId] as Map<String, dynamic>;
      // Restore company document
      await _firestore.collection('companies').doc(companyId).set(convertIsoStringsToTimestamps(Map<String, dynamic>.from(companyMap['companyData'])));
      // Restore users
      if (companyMap['users'] is List) {
        for (final user in companyMap['users']) {
          final userId = user['id'];
          final userData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(user)..remove('id'));
          await _firestore.collection('companies').doc(companyId).collection('users').doc(userId).set(userData);
          // Restore sessions
          if (user['sessions'] is List) {
            for (final session in user['sessions']) {
              final sessionId = session['id'];
              final sessionData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(session)..remove('id'));
              await _firestore.collection('companies').doc(companyId).collection('users').doc(userId).collection('sessions').doc(sessionId).set(sessionData);
              // Restore logs
              if (session['logs'] is List) {
                for (final log in session['logs']) {
                  final logId = log['id'];
                  final logData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(log)..remove('id'));
                  await _firestore.collection('companies').doc(companyId).collection('users').doc(userId).collection('sessions').doc(sessionId).collection('logs').doc(logId).set(logData);
                }
              }
            }
          }
          // Restore all_logs
          if (user['all_logs'] is List) {
            for (final log in user['all_logs']) {
              final logId = log['id'];
              final logData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(log)..remove('id'));
              await _firestore.collection('companies').doc(companyId).collection('users').doc(userId).collection('all_logs').doc(logId).set(logData);
            }
          }
        }
      }
      // Restore projects
      if (companyMap['projects'] is List) {
        for (final project in companyMap['projects']) {
          final projectId = project['id'];
          final projectData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(project)..remove('id'));
          await _firestore.collection('companies').doc(companyId).collection('projects').doc(projectId).set(projectData);
        }
      }
      // Restore clients
      if (companyMap['clients'] is List) {
        for (final client in companyMap['clients']) {
          final clientId = client['id'];
          final clientData = convertIsoStringsToTimestamps(Map<String, dynamic>.from(client)..remove('id'));
          await _firestore.collection('companies').doc(companyId).collection('clients').doc(clientId).set(clientData);
        }
      }
    }
  }
} 