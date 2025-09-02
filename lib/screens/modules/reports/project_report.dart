import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProjectReport {
  final String companyId;
  final Map<String, dynamic> reportConfig;
  final String Function()? getPerDiemTranslation;
  
  ProjectReport({
    required this.companyId,
    required this.reportConfig,
    this.getPerDiemTranslation,
  });

  // Store project data for tabs/sheets
  // ignore: prefer_final_fields
  Map<String, Map<String, dynamic>> _projectReportData = {};

  Map<String, Map<String, dynamic>> get projectReportData => _projectReportData;

  String _formatAddress(dynamic address) {
    if (address == null) return '';
    
    try {
      if (address is Map<String, dynamic>) {
        // Address is already a Map
        final List<String> parts = [];
        
        if (address['street'] != null && address['street'].toString().isNotEmpty) {
          parts.add(address['street'].toString());
        }
        if (address['number'] != null && address['number'].toString().isNotEmpty) {
          parts.add(address['number'].toString());
        }
        if (address['post_code'] != null && address['post_code'].toString().isNotEmpty) {
          parts.add(address['post_code'].toString());
        }
        if (address['city'] != null && address['city'].toString().isNotEmpty) {
          parts.add(address['city'].toString());
        }
        
        return parts.join(', ');
      } else if (address is String) {
        // Try to parse as JSON string
        final Map<String, dynamic> addressMap = jsonDecode(address);
        final List<String> parts = [];
        
        if (addressMap['street'] != null && addressMap['street'].toString().isNotEmpty) {
          parts.add(addressMap['street'].toString());
        }
        if (addressMap['number'] != null && addressMap['number'].toString().isNotEmpty) {
          parts.add(addressMap['number'].toString());
        }
        if (addressMap['post_code'] != null && addressMap['post_code'].toString().isNotEmpty) {
          parts.add(addressMap['post_code'].toString());
        }
        if (addressMap['city'] != null && addressMap['city'].toString().isNotEmpty) {
          parts.add(addressMap['city'].toString());
        }
        
        return parts.join(', ');
      }
    } catch (e) {
      // If parsing fails, return the original value as string
    }
    
    return address.toString();
  }

  Future<void> generateReport() async {
    final projectId = reportConfig['projectId'] as String?;
    final dateRange = reportConfig['dateRange'] as Map<String, dynamic>?;
    
    if (projectId != null) {
      // Single project report
      await _generateSingleProjectReport(projectId, dateRange);
    } else {
      // Multiple projects report
      await _generateMultipleProjectsReport(dateRange);
    }
  }

  Future<void> _generateSingleProjectReport(String projectId, Map<String, dynamic>? dateRange) async {
    // Get project details
    final projectDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectDoc.exists) return;

    final projectData = projectDoc.data() ?? {};
    final projectName = projectData['name']?.toString() ?? 'Unknown Project';
    
    // Get client details
    final clientId = projectData['client']?.toString();
    
    String clientName = 'Unknown Client';
    String clientAddress = '';
    String clientContact = '';
    String clientEmail = '';
    String clientPhone = '';
    if (clientId != null) {
      final clientDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .doc(clientId)
          .get();
      if (clientDoc.exists) {
        final clientData = clientDoc.data() ?? {};
        clientName = clientData['name']?.toString() ?? 'Unknown Client';
        
        // Format client address from individual components
        final clientStreet = clientData['street']?.toString() ?? '';
        final clientNumber = clientData['number']?.toString() ?? '';
        final clientPostCode = clientData['post_code']?.toString() ?? '';
        final clientCity = clientData['city']?.toString() ?? '';
        
        final clientAddressParts = <String>[];
        if (clientStreet.isNotEmpty) clientAddressParts.add(clientStreet);
        if (clientNumber.isNotEmpty) clientAddressParts.add(clientNumber);
        if (clientPostCode.isNotEmpty) clientAddressParts.add(clientPostCode);
        if (clientCity.isNotEmpty) clientAddressParts.add(clientCity);
        clientAddress = clientAddressParts.join(' ');
        
        // Get contact person from contact_person object
        final contactPerson = clientData['contact_person'] as Map<String, dynamic>? ?? {};
        final firstName = contactPerson['first_name']?.toString() ?? '';
        final surname = contactPerson['surname']?.toString() ?? '';
        clientContact = '$firstName $surname'.trim();
        
        clientEmail = clientData['email']?.toString() ?? '';
        clientPhone = clientData['phone']?.toString() ?? '';
      }
    }

    // Get users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .get();

    final allLogs = <Map<String, dynamic>>[];

    // Get logs for this project from all users
    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final firstName = userData['firstName']?.toString() ?? '';
      final surname = userData['surname']?.toString() ?? '';
      final userName = (firstName.isNotEmpty && surname.isNotEmpty) 
          ? '$firstName $surname'
          : userData['name']?.toString() ?? 
            userData['displayName']?.toString() ?? 
            userData['email']?.toString() ?? 
            'Unknown User';

      // Get all logs for this user, then filter in code to avoid index requirement
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs')
          .get();

      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        
        // Filter by project ID in code
        final logProjectId = logData['projectId']?.toString();
        if (logProjectId != projectId) continue;
        
        // Filter by date range if specified
        if (dateRange != null) {
          final timestamp = logData['begin'] as Timestamp?;
          if (timestamp != null) {
            final logDate = timestamp.toDate();
            if (dateRange['startDate'] != null) {
              final startDate = (dateRange['startDate'] as Timestamp).toDate();
              if (logDate.isBefore(startDate)) continue;
            }
            if (dateRange['endDate'] != null) {
              final endDate = (dateRange['endDate'] as Timestamp).toDate();
              if (logDate.isAfter(endDate.add(const Duration(days: 1)))) continue;
            }
          }
        }
        
        final rowData = <String, dynamic>{};

        // Date
        final timestamp = logData['begin'] as Timestamp?;
        if (timestamp != null) {
          rowData['Date'] = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
          rowData['Month'] = DateFormat('MMMM').format(timestamp.toDate());
          rowData['Week'] = 'W${_getWeekNumber(timestamp.toDate())}';
        } else {
          rowData['Date'] = '';
          rowData['Month'] = '';
          rowData['Week'] = '';
        }

        // Worker (not Project name)
        rowData['Worker'] = userName;

        // Start time
        final begin = logData['begin'] as Timestamp?;
        rowData['Start'] = begin != null ? DateFormat('HH:mm').format(begin.toDate()) : '';

        // End time
        final end = logData['end'] as Timestamp?;
        rowData['End'] = end != null ? DateFormat('HH:mm').format(end.toDate()) : '';

        // Duration
        final minutes = (logData['duration_minutes'] as num?)?.toInt() ?? 0;
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        rowData['Duration'] = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} h';
        rowData['TotalMinutes'] = minutes;

        // Note
        rowData['Note'] = logData['note']?.toString() ?? '';

        // Expenses
        final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
        final expenseDetails = <String>[];
        double totalExpenses = 0.0;
        
        for (var entry in expenses.entries) {
          final value = entry.value;
          if (value is num && value > 0) {
            // Translate "Per diem" key if it exists
            String displayKey = entry.key;
            if (entry.key == 'Per diem' && getPerDiemTranslation != null) {
              displayKey = getPerDiemTranslation!();
            }
            expenseDetails.add('$displayKey: $value');
            totalExpenses += value.toDouble();
          }
        }
        
        if (logData['perDiem'] == true) {
          final perDiemText = getPerDiemTranslation?.call() ?? 'Per diem';
          expenseDetails.add('$perDiemText: 16');
          totalExpenses += 16.0;
        }
        
        rowData['Expenses'] = expenseDetails.join(', ');
        rowData['TotalExpenses'] = totalExpenses;
        
        // Add project and client details
        rowData['ProjectRef'] = projectData['refNumber']?.toString() ?? '';
        rowData['ProjectAddress'] = _formatAddress(projectData['address']);
        rowData['Client'] = clientName;
        rowData['ClientAddress'] = _formatAddress(clientAddress);

        allLogs.add(rowData);
      }
    }

    // Sort by date in descending order (most recent first)
    allLogs.sort((a, b) {
      final dateA = a['Date'] as String? ?? '';
      final dateB = b['Date'] as String? ?? '';
      return dateB.compareTo(dateA);
    });

    _projectReportData[projectId] = {
      'projectName': projectName,
      'projectId': projectId,
      'projectRef': projectData['projectRef']?.toString() ?? '',
      'projectAddress': _formatAddress(projectData['address']),
      'clientName': clientName,
      'clientAddress': _formatAddress(clientAddress),
      'clientContact': clientContact,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'totalSessions': allLogs.length,
      'totalTime': '${allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)) ~/ 60}:${allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)) % 60} h',
      'totalMinutes': allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)),
      'totalExpenses': allLogs.fold<double>(0, (total, log) => total + ((log['TotalExpenses'] as double?) ?? 0)),
      'sessions': allLogs,
      'groupedSessions': _groupSessionsByTimePeriod(allLogs),
    };
  }

  Future<void> _generateMultipleProjectsReport(Map<String, dynamic>? dateRange) async {
    // Get all projects, optionally filtered by client
    Query projectsQuery = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects');
    
         // If a specific client is selected, filter projects by that client
     final clientId = reportConfig['clientId']?.toString();
     if (clientId != null && clientId.isNotEmpty) {
       projectsQuery = projectsQuery.where('client', isEqualTo: clientId);
     }
    
    final projectsSnapshot = await projectsQuery.get();

    // Get users for lookup
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .get();
    
    final usersMap = <String, String>{};
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final firstName = data['firstName']?.toString() ?? '';
      final surname = data['surname']?.toString() ?? '';
      final fullName = (firstName.isNotEmpty && surname.isNotEmpty) 
          ? '$firstName $surname'
          : data['name']?.toString() ?? 
            data['displayName']?.toString() ?? 
            data['email']?.toString() ?? 
            'Unknown User';
      usersMap[doc.id] = fullName;
    }

    // Process each project
    for (final projectDoc in projectsSnapshot.docs) {
      final projectId = projectDoc.id;
      final projectData = projectDoc.data() as Map<String, dynamic>?;
      final projectName = projectData?['name']?.toString() ?? 'Unknown Project';
      
                    // Get client details for this project
        final projectClientId = projectData?['client']?.toString();
        
        String clientName = 'Unknown Client';
        String clientAddress = '';
        String clientContact = '';
        String clientEmail = '';
        String clientPhone = '';
        if (projectClientId != null) {
          final clientDoc = await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('clients')
              .doc(projectClientId)
              .get();
          if (clientDoc.exists) {
            final clientData = clientDoc.data() ?? {};
            clientName = clientData['name']?.toString() ?? 'Unknown Client';
            
            // Format client address from individual components
            final clientStreet = clientData['street']?.toString() ?? '';
            final clientNumber = clientData['number']?.toString() ?? '';
            final clientPostCode = clientData['post_code']?.toString() ?? '';
            final clientCity = clientData['city']?.toString() ?? '';
            
            final clientAddressParts = <String>[];
            if (clientStreet.isNotEmpty) clientAddressParts.add(clientStreet);
            if (clientNumber.isNotEmpty) clientAddressParts.add(clientNumber);
            if (clientPostCode.isNotEmpty) clientAddressParts.add(clientPostCode);
            if (clientCity.isNotEmpty) clientAddressParts.add(clientCity);
            clientAddress = clientAddressParts.join(' ');
            
            // Get contact person from contact_person object
            final contactPerson = clientData['contact_person'] as Map<String, dynamic>? ?? {};
            final firstName = contactPerson['first_name']?.toString() ?? '';
            final surname = contactPerson['surname']?.toString() ?? '';
            clientContact = '$firstName $surname'.trim();
            
            clientEmail = clientData['email']?.toString() ?? '';
            clientPhone = clientData['phone']?.toString() ?? '';
          }
        }

      final allLogs = <Map<String, dynamic>>[];

      // Get logs for this project from all users
      for (final userDoc in usersSnapshot.docs) {
        final userName = usersMap[userDoc.id] ?? 'Unknown User';

        // Get all logs for this user, then filter in code
        final logsSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('users')
            .doc(userDoc.id)
            .collection('all_logs')
            .get();

        for (final logDoc in logsSnapshot.docs) {
          final logData = logDoc.data();
          
          // Filter by project ID in code
          final logProjectId = logData['projectId']?.toString();
          if (logProjectId != projectId) continue;
          
          // Filter by date range if specified
          if (dateRange != null) {
            final timestamp = logData['begin'] as Timestamp?;
            if (timestamp != null) {
              final logDate = timestamp.toDate();
              if (dateRange['startDate'] != null) {
                final startDate = (dateRange['startDate'] as Timestamp).toDate();
                if (logDate.isBefore(startDate)) continue;
              }
              if (dateRange['endDate'] != null) {
                final endDate = (dateRange['endDate'] as Timestamp).toDate();
                if (logDate.isAfter(endDate.add(const Duration(days: 1)))) continue;
              }
            }
          }
          
          final rowData = <String, dynamic>{};

          // Date
          final timestamp = logData['begin'] as Timestamp?;
          if (timestamp != null) {
            rowData['Date'] = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
            rowData['Month'] = DateFormat('MMMM').format(timestamp.toDate());
            rowData['Week'] = 'W${_getWeekNumber(timestamp.toDate())}';
          } else {
            rowData['Date'] = '';
            rowData['Month'] = '';
            rowData['Week'] = '';
          }

                                     // Worker (not Project name)
         rowData['Worker'] = userName;

          // Start time
          final begin = logData['begin'] as Timestamp?;
          rowData['Start'] = begin != null ? DateFormat('HH:mm').format(begin.toDate()) : '';

          // End time
          final end = logData['end'] as Timestamp?;
          rowData['End'] = end != null ? DateFormat('HH:mm').format(end.toDate()) : '';

          // Duration
          final minutes = (logData['duration_minutes'] as num?)?.toInt() ?? 0;
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          rowData['Duration'] = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} h';
          rowData['TotalMinutes'] = minutes;

          // Note
          rowData['Note'] = logData['note']?.toString() ?? '';

          // Expenses
          final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
          final expenseDetails = <String>[];
          double totalExpenses = 0.0;
          
          for (var entry in expenses.entries) {
            final value = entry.value;
            if (value is num && value > 0) {
              // Translate "Per diem" key if it exists
              String displayKey = entry.key;
              if (entry.key == 'Per diem' && getPerDiemTranslation != null) {
                displayKey = getPerDiemTranslation!();
              }
              expenseDetails.add('$displayKey: $value');
              totalExpenses += value.toDouble();
            }
          }
          
           if (logData['perDiem'] == true) {
             final perDiemText = getPerDiemTranslation?.call() ?? 'Per diem';
             expenseDetails.add('$perDiemText: 16');
             totalExpenses += 16.0;
           }
          
          rowData['Expenses'] = expenseDetails.join(', ');
          rowData['TotalExpenses'] = totalExpenses;
          
          // Add project and client details
          rowData['ProjectRef'] = projectData?['refNumber']?.toString() ?? '';
          rowData['ProjectAddress'] = _formatAddress(projectData?['address']);
          rowData['Client'] = clientName;
          rowData['ClientAddress'] = _formatAddress(clientAddress);

          allLogs.add(rowData);
        }
      }

      // Sort by date in descending order
      allLogs.sort((a, b) {
        final dateA = a['Date'] as String? ?? '';
        final dateB = b['Date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });

      if (allLogs.isNotEmpty) {
        _projectReportData[projectId] = {
          'projectName': projectName,
          'projectId': projectId,
          'projectRef': projectData?['projectRef']?.toString() ?? '',
          'projectAddress': _formatAddress(projectData?['address']),
          'clientName': clientName,
          'clientAddress': _formatAddress(clientAddress),
          'clientContact': clientContact,
          'clientEmail': clientEmail,
          'clientPhone': clientPhone,
          'totalSessions': allLogs.length,
          'totalTime': '${allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)) ~/ 60}:${allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)) % 60} h',
          'totalMinutes': allLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0)),
          'totalExpenses': allLogs.fold<double>(0, (total, log) => total + ((log['TotalExpenses'] as double?) ?? 0)),
          'sessions': allLogs,
          'groupedSessions': _groupSessionsByTimePeriod(allLogs),
        };
      }
    }
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.add(Duration(days: (8 - startOfYear.weekday) % 7));
    if (date.isBefore(firstMonday)) return 1;
    return ((date.difference(firstMonday).inDays) / 7).floor() + 2;
  }

  Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>> _groupSessionsByTimePeriod(
      List<Map<String, dynamic>> sessions) {
    final grouped = <String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>{};
    
    for (final session in sessions) {
      final month = session['Month'] as String? ?? '';
      final week = session['Week'] as String? ?? '';
      final day = session['Date'] as String? ?? '';
      
      // Group by: Year -> Month -> Week -> Day -> Sessions
      grouped.putIfAbsent('2025', () => {});
      grouped['2025']!.putIfAbsent(month, () => {});
      grouped['2025']![month]!.putIfAbsent(week, () => {});
      grouped['2025']![month]![week]!.putIfAbsent(day, () => []);
      
      // Add session to day group
      grouped['2025']![month]![week]![day]!.add(session);
    }
    
    return grouped;
  }
}


