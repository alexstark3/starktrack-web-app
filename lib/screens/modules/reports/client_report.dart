import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClientReport {
  final String companyId;
  final Map<String, dynamic> reportConfig;
  
  ClientReport({
    required this.companyId,
    required this.reportConfig,
  });

  // Store client data for tabs/sheets
  // ignore: prefer_final_fields
  Map<String, Map<String, dynamic>> _clientReportData = {};



  Map<String, Map<String, dynamic>> get clientReportData => _clientReportData;

  /// Format address object to readable string
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
        return address;
      }
    } catch (e) {
      // If parsing fails, return empty string
    }
    
    return '';
  }

  Future<void> generateReport() async {
    try {
      // Get clients
      final clientsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .get();

      // Get projects
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('projects')
          .get();

      // Get users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .get();

      final usersMap = <String, String>{};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        // Build full name from firstName + surname
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

      // For each client, generate report data
      for (final clientDoc in clientsSnapshot.docs) {
        final clientData = clientDoc.data();
        final clientName = clientData['name']?.toString() ?? 'Unknown Client';
        
        // Format client address from individual components (same as project report)
        final clientStreet = clientData['street']?.toString() ?? '';
        final clientNumber = clientData['number']?.toString() ?? '';
        final clientPostCode = clientData['post_code']?.toString() ?? '';
        final clientCity = clientData['city']?.toString() ?? '';
        
        final clientAddressParts = <String>[];
        if (clientStreet.isNotEmpty) clientAddressParts.add(clientStreet);
        if (clientNumber.isNotEmpty) clientAddressParts.add(clientNumber);
        if (clientPostCode.isNotEmpty) clientAddressParts.add(clientPostCode);
        if (clientCity.isNotEmpty) clientAddressParts.add(clientCity);
        final clientAddress = clientAddressParts.join(' ');
        
        // Get contact person from contact_person object (same as project report)
        final contactPerson = clientData['contact_person'] as Map<String, dynamic>? ?? {};
        final firstName = contactPerson['first_name']?.toString() ?? '';
        final surname = contactPerson['surname']?.toString() ?? '';
        final clientContact = '$firstName $surname'.trim();
        
        final clientEmail = clientData['email']?.toString() ?? '';
        final clientPhone = clientData['phone']?.toString() ?? '';
        final clientCountry = clientData['country']?.toString() ?? '';

        // Find all projects for this client
        final clientProjects = projectsSnapshot.docs.where(
          (project) => project.data()['client'] == clientDoc.id
        ).toList();

        final clientProjectsData = <Map<String, dynamic>>[];
        int totalClientMinutes = 0;
        double totalClientExpenses = 0.0;

        // Process each project for this client
        for (final projectDoc in clientProjects) {
          final projectData = projectDoc.data();
          final projectName = projectData['name']?.toString() ?? 'Unknown Project';
          final projectRef = projectData['projectRef']?.toString() ?? '';
          final projectAddress = _formatAddress(projectData['address']);
          
          int totalProjectMinutes = 0;
          double totalProjectExpenses = 0.0;
          final projectSessions = <Map<String, dynamic>>[];

          // Get logs from all users for this project
          for (final userDoc in usersSnapshot.docs) {
            final userName = usersMap[userDoc.id] ?? 'Unknown User';

            final logsSnapshot = await FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('users')
                .doc(userDoc.id)
                .collection('all_logs')
                .get();

            for (final logDoc in logsSnapshot.docs) {
              final logData = logDoc.data();
              
              // Filter by project ID
              if (logData['projectId'] != projectDoc.id) continue;
              
              final timestamp = logData['begin'] as Timestamp?;
              if (timestamp == null) continue;

              final sessionDate = timestamp.toDate();
              final minutes = (logData['duration_minutes'] as num?)?.toInt() ?? 0;
              
              if (minutes > 0) {
                totalProjectMinutes += minutes;
                
                // Calculate expenses for this session
                double sessionExpenses = 0.0;
                final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
                final expenseDetails = <String>[];
                
                for (var entry in expenses.entries) {
                  final value = entry.value;
                  if (value is num && value > 0) {
                    expenseDetails.add('${entry.key}: $value');
                    sessionExpenses += value.toDouble();
                  }
                }
                
                if (logData['perDiem'] == true) {
                  expenseDetails.add('Per diem: 16');
                  sessionExpenses += 16.0;
                }
                
                totalProjectExpenses += sessionExpenses;

                // Create session entry
                final sessionEntry = {
                  'Date': DateFormat('dd/MM/yyyy').format(sessionDate),
                  'Day': DateFormat('EEE').format(sessionDate),
                  'Month': DateFormat('MMMM').format(sessionDate),
                  'Week': 'W${_getWeekNumber(sessionDate)}',
                  'Project': projectName,
                  'Start': logData['begin'] != null ? DateFormat('HH:mm').format((logData['begin'] as Timestamp).toDate()) : '',
                  'End': logData['end'] != null ? DateFormat('HH:mm').format((logData['end'] as Timestamp).toDate()) : '',
                  'Duration': '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')} h',
                  'TotalMinutes': minutes,
                  'Worker': userName,
                  'Note': logData['note']?.toString() ?? '',
                  'Expenses': expenseDetails.join(', '),
                  'TotalExpenses': sessionExpenses,
                };

                projectSessions.add(sessionEntry);
              }
            }
          }

          // Add project summary to client projects data
          if (totalProjectMinutes > 0 || totalProjectExpenses > 0) {
            clientProjectsData.add({
              'projectId': projectDoc.id,
              'projectName': projectName,
              'projectRef': projectRef,
              'projectAddress': projectAddress,
              'totalTime': '${(totalProjectMinutes ~/ 60).toString().padLeft(2, '0')}:${(totalProjectMinutes % 60).toString().padLeft(2, '0')} h',
              'totalMinutes': totalProjectMinutes,
              'totalExpenses': totalProjectExpenses,
              'sessions': projectSessions,
            });

            totalClientMinutes += totalProjectMinutes;
            totalClientExpenses += totalProjectExpenses;
          }
        }

        // Sort projects by total time (descending)
        clientProjectsData.sort((a, b) => (b['totalMinutes'] as int).compareTo(a['totalMinutes'] as int));

        // Sort sessions by date (descending)
        for (final project in clientProjectsData) {
          final sessions = project['sessions'] as List<Map<String, dynamic>>;
          sessions.sort((a, b) {
            final dateA = a['Date'] as String? ?? '';
            final dateB = b['Date'] as String? ?? '';
            return dateB.compareTo(dateA);
          });
        }

        // Store client data
        _clientReportData[clientDoc.id] = {
          'clientId': clientDoc.id,
          'clientName': clientName,
          'clientAddress': clientAddress,
          'clientContact': clientContact,
          'clientEmail': clientEmail,
          'clientPhone': clientPhone,
          'clientCity': clientCity,
          'clientCountry': clientCountry,
          'totalProjects': clientProjectsData.length,
          'totalTime': '${(totalClientMinutes ~/ 60).toString().padLeft(2, '0')}:${(totalClientMinutes % 60).toString().padLeft(2, '0')} h',
          'totalMinutes': totalClientMinutes,
          'totalExpenses': totalClientExpenses,
          'reportGenerated': DateTime.now(),
          'projects': clientProjectsData,
          'groupedProjects': _groupProjectsByTimePeriod(clientProjectsData),
        };
      }
    } catch (e) {
      // Handle error
    }
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.add(Duration(days: (8 - startOfYear.weekday) % 7));
    if (date.isBefore(firstMonday)) return 1;
    return ((date.difference(firstMonday).inDays) / 7).floor() + 2;
  }

  Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>> _groupProjectsByTimePeriod(
      List<Map<String, dynamic>> projects) {
    final grouped = <String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>{};
    
    for (final project in projects) {
      final sessions = project['sessions'] as List<Map<String, dynamic>>;
      
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
    }
    
    return grouped;
  }
}
