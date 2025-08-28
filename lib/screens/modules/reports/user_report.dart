import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/overtime_calculation_service.dart';

class UserReport {
  final String companyId;
  final Map<String, dynamic> reportConfig;
  
  UserReport({
    required this.companyId,
    required this.reportConfig,
  });

  // Store user data for tabs/sheets
  // ignore: prefer_final_fields
  Map<String, Map<String, dynamic>> _userReportData = {};

  /// Convert various types to double for vacation calculations
  double _convertToDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Convert various types to minutes for overtime calculations
  int _convertToMinutes(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return (value * 60).round();
    } else if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null ? (parsed * 60).round() : 0;
    }
    return 0;
  }

  Map<String, Map<String, dynamic>> get userReportData => _userReportData;

  Future<void> generateReport() async {
    final selectedUserId = reportConfig['userId'] as String?;
    final dateRange = reportConfig['dateRange'] as Map<String, dynamic>?;
    
    // Get all users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .get();

    // Get projects for lookup
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .get();
    
    final projectsMap = <String, String>{};
    for (var doc in projectsSnapshot.docs) {
      final data = doc.data();
      projectsMap[doc.id] = data['name']?.toString() ?? 'Unknown Project';
    }

    // Process users - either all users or just the selected one
    final usersToProcess = selectedUserId != null 
        ? usersSnapshot.docs.where((doc) => doc.id == selectedUserId).toList()
        : usersSnapshot.docs;

    // Store user data for tabs/sheets
    _userReportData = <String, Map<String, dynamic>>{};

    for (final userDoc in usersToProcess) {
      final userData = userDoc.data();
      final firstName = userData['firstName']?.toString() ?? '';
      final surname = userData['surname']?.toString() ?? '';
      final userName = (firstName.isNotEmpty && surname.isNotEmpty) 
          ? '$firstName $surname'
          : userData['name']?.toString() ?? 
            userData['displayName']?.toString() ?? 
            userData['email']?.toString() ?? 
            'Unknown User';

      // Get logs for this user
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs')
          .get();
      
      // Get time off records for this user from company-level collection
      List<Map<String, dynamic>> timeOffRecords = <Map<String, dynamic>>[];
      
      try {
        final timeOffSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('timeoff_requests')
            .where('userId', isEqualTo: userDoc.id)
            .get();
        
        for (final doc in timeOffSnapshot.docs) {
          final data = doc.data();
          final record = {
            'startDate': data['startDate'] as Timestamp?,
            'endDate': data['endDate'] as Timestamp?,
            'type': data['type']?.toString() ?? 'Unknown',
            'hours': data['hours'] as num? ?? 0,
            'status': data['status']?.toString() ?? 'Unknown',
          };
          timeOffRecords.add(record);
        }
      } catch (e) {
        timeOffRecords = <Map<String, dynamic>>[];
      }
      


      // Filter logs by date range if specified
      final userLogs = <Map<String, dynamic>>[];
      DateTime? startDate, endDate;
      
      if (dateRange != null) {
        if (dateRange['startDate'] != null) {
          startDate = (dateRange['startDate'] as Timestamp).toDate();
        }
        if (dateRange['endDate'] != null) {
          endDate = (dateRange['endDate'] as Timestamp).toDate();
        }
      }
      
      for (int i = 0; i < logsSnapshot.docs.length; i++) {
        final logDoc = logsSnapshot.docs[i];
        
        try {
          final logData = logDoc.data();
          final timestamp = logData['begin'] as Timestamp?;
          
          // Filter by date range if specified
          if (timestamp != null && (startDate != null || endDate != null)) {
            final logDate = timestamp.toDate();
            
            if (startDate != null && logDate.isBefore(startDate)) {
              continue;
            }
            if (endDate != null && logDate.isAfter(endDate.add(const Duration(days: 1)))) {
              continue;
            }
          }

          final logEntry = <String, dynamic>{};
        
        // Basic session info
        if (timestamp != null) {
          logEntry['Date'] = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
          logEntry['Day'] = DateFormat('EEE').format(timestamp.toDate());
          logEntry['Month'] = DateFormat('MMMM').format(timestamp.toDate());
          logEntry['Week'] = 'W${_getWeekNumber(timestamp.toDate())}';
        } else {
          logEntry['Date'] = '';
          logEntry['Day'] = '';
          logEntry['Month'] = '';
          logEntry['Week'] = '';
        }

        // Project info
        final projectId = logData['projectId']?.toString();
        logEntry['Project'] = projectsMap[projectId] ?? 'Unknown Project';

        // Start and end times
        final begin = logData['begin'] as Timestamp?;
        final end = logData['end'] as Timestamp?;
        logEntry['Start'] = begin != null ? DateFormat('HH:mm').format(begin.toDate()) : '';
        logEntry['End'] = end != null ? DateFormat('HH:mm').format(end.toDate()) : '';

        // Duration
        final minutes = (logData['duration_minutes'] as num?)?.toInt() ?? 0;
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        logEntry['Duration'] = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} h';
        logEntry['TotalMinutes'] = minutes;

        // Overtime will be calculated per day and shown after the date
        logEntry['Overtime'] = '';

        // Note
        logEntry['Note'] = logData['note']?.toString() ?? '';

        // Expenses
        final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
        final expenseDetails = <String>[];
        double totalExpenses = 0.0;
        
        for (var entry in expenses.entries) {
          final value = entry.value;
          if (value is num && value > 0) {
            expenseDetails.add('${entry.key}: $value');
            totalExpenses += value.toDouble();
          }
        }
        
        if (logData['perDiem'] == true) {
          expenseDetails.add('Per diem: 16');
          totalExpenses += 16.0;
        }
        
        logEntry['Expenses'] = expenseDetails.join(', ');
        logEntry['TotalExpenses'] = totalExpenses;

        // Add time off information for this date
        final sessionDate = timestamp?.toDate();
        if (sessionDate != null) {
          final timeOffForDate = timeOffRecords.where((record) {
            final recordDate = record['date'] as Timestamp?;
            if (recordDate == null) return false;
            final recordDateTime = recordDate.toDate();
            return recordDateTime.year == sessionDate.year &&
                   recordDateTime.month == sessionDate.month &&
                   recordDateTime.day == sessionDate.day;
          }).toList();
          
          if (timeOffForDate.isNotEmpty) {
            // Show time off details for this date
            final timeOffDetails = timeOffForDate.map((record) {
              final type = record['type']?.toString() ?? '';
              final hours = record['hours']?.toString() ?? '0';
              return '$type: $hours h';
            }).join(', ');
            logEntry['TimeOff'] = timeOffDetails;
          } else {
            logEntry['TimeOff'] = '';
          }
        } else {
          logEntry['TimeOff'] = '';
        }

        userLogs.add(logEntry);
        } catch (e) {
          continue;
        }
      }

      // Sort by date in descending order
      userLogs.sort((a, b) {
        final dateA = a['Date'] as String? ?? '';
        final dateB = b['Date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });

      // Calculate daily overtime for each date from the original logsSnapshot (not filtered)
      final dailyOvertime = <String, String>{};
      
      // Group all logs by date to calculate actual daily totals
      final dailyLogsByDate = <String, List<int>>{};
      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        final timestamp = logData['begin'] as Timestamp?;
        final minutes = (logData['duration_minutes'] as num?)?.toInt() ?? 0;
        
        if (timestamp != null && minutes > 0) {
          final dateKey = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
          dailyLogsByDate.putIfAbsent(dateKey, () => []).add(minutes);
        }
      }
      
      // Calculate overtime for each day
      for (final entry in dailyLogsByDate.entries) {
        final date = entry.key;
        final dayMinutes = entry.value.fold<int>(0, (total, minutes) => total + minutes);
        
        // Get user's working days configuration
        final workingDaysStr = userData['workingDays']?.toString() ?? 'Monday,Tuesday,Wednesday,Thursday,Friday';
        final workingDaysList = workingDaysStr.split(',').map((dayName) {
          switch (dayName.trim()) {
            case 'Monday': return 1;
            case 'Tuesday': return 2;
            case 'Wednesday': return 3;
            case 'Thursday': return 4;
            case 'Friday': return 5;
            case 'Saturday': return 6;
            case 'Sunday': return 7;
            default: return 0;
          }
        }).where((d) => d > 0).toList();
        final weeklyHours = userData['weeklyHours'] ?? 40;
        final dailyHours = weeklyHours / workingDaysList.length;
        final standardDayMinutes = (dailyHours * 60).round(); // Calculate based on user's config
        
        final overtimeMinutes = dayMinutes - standardDayMinutes;
        
        if (overtimeMinutes != 0) {
          final overtimeHours = overtimeMinutes.abs() ~/ 60;
          final overtimeMins = overtimeMinutes.abs() % 60;
          final sign = overtimeMinutes > 0 ? '+' : '-';
          dailyOvertime[date] = '$sign${overtimeHours.toString().padLeft(2, '0')}:${overtimeMins.toString().padLeft(2, '0')} h';
        } else {
          dailyOvertime[date] = '0:00 h';
        }
      }
      
      // Assign daily overtime to each session
      for (final log in userLogs) {
        final date = log['Date'] as String? ?? '';
        if (date.isNotEmpty) {
          log['Overtime'] = dailyOvertime[date] ?? '0:00 h';
        }
      }

      // Calculate totals
      final totalMinutes = userLogs.fold<int>(0, (total, log) => total + ((log['TotalMinutes'] as int?) ?? 0));
      final totalHours = totalMinutes ~/ 60;
      final totalMins = totalMinutes % 60;
      final totalTime = '${totalHours.toString().padLeft(2, '0')}:${totalMins.toString().padLeft(2, '0')} h';
      final totalExpenses = userLogs.fold<double>(0, (total, log) => total + ((log['TotalExpenses'] as double?) ?? 0));
      
      // Calculate overtime balance using the same method as balance pages (from user start date)
      int totalOvertimeMinutes = 0;
      
      try {
        // Use the OvertimeCalculationService to get the same calculation as balance pages
        final overtimeData = await OvertimeCalculationService.calculateOvertimeFromLogs(
          companyId,
          userDoc.id,
        );
        
        // Get the current overtime value (same as balance page)
        totalOvertimeMinutes = overtimeData['current'] as int? ?? 0;
      } catch (e) {
        // Fallback to stored overtime data if calculation fails
        final userOvertimeData = userData['overtime'] ?? {};
        totalOvertimeMinutes = _convertToMinutes(userOvertimeData['current'] ?? 0);
      }
      
      final isNegative = totalOvertimeMinutes < 0;
      final abs = totalOvertimeMinutes.abs();
      final totalOvertimeHours = abs ~/ 60;
      final totalOvertimeMins = abs % 60;
      final sign = isNegative ? '-' : '';
      final totalOvertime = '$sign${totalOvertimeHours.toString().padLeft(2, '0')}:${totalOvertimeMins.toString().padLeft(2, '0')} h';

      // Calculate vacation balance
      double totalVacationDays = 0.0;
      double totalSickDays = 0.0;
      double totalOtherTimeOff = 0.0;
      
      
      
      for (final record in timeOffRecords) {
        final type = record['type']?.toString().toLowerCase() ?? '';
        final days = (record['totalWorkingDays'] as num?) ?? 0;
        final status = record['status']?.toString().toLowerCase() ?? '';
        final startDate = record['startDate'] as Timestamp?;
        final endDate = record['endDate'] as Timestamp?;
        
        if (status == 'approved' && startDate != null && endDate != null) {
          // Get user's working days configuration for accurate day calculation
          final workingDaysStr = userData['workingDays']?.toString() ?? 'Monday,Tuesday,Wednesday,Thursday,Friday';
          final workingDaysList = workingDaysStr.split(',').map((dayName) {
            switch (dayName.trim()) {
              case 'Monday': return 1;
              case 'Tuesday': return 2;
              case 'Wednesday': return 3;
              case 'Thursday': return 4;
              case 'Friday': return 5;
              case 'Saturday': return 6;
              case 'Sunday': return 7;
              default: return 0;
            }
          }).where((d) => d > 0).toList();
          // Calculate ONLY working days (exclude weekends and non-working days)
          int workingDaysCount = 0;
          for (DateTime date = startDate.toDate(); !date.isAfter(endDate.toDate()); date = date.add(const Duration(days: 1))) {
            if (workingDaysList.contains(date.weekday)) {
              workingDaysCount++;
            }
          }
          

          
          // Use days directly if provided, otherwise use calculated working days
          final daysToAdd = days > 0 ? days : workingDaysCount.toDouble();
          
          if (type.contains('vacation') || type.contains('urlaub')) {
            totalVacationDays += daysToAdd;
          } else if (type.contains('sick') || type.contains('krank')) {
            totalSickDays += daysToAdd;
          } else {
            totalOtherTimeOff += daysToAdd;
          }
        }
      }
      

      
      // Read vacation data from user document (same as balance page)
      final userVacationData = userData['annualLeaveDays'] as Map<String, dynamic>? ?? {};
      final transferred = _convertToDouble(userVacationData['transferred'] ?? 0);
      final current = _convertToDouble(userVacationData['current'] ?? 0);
      final bonus = _convertToDouble(userVacationData['bonus'] ?? 0);
      final used = _convertToDouble(userVacationData['used'] ?? 0);
      
      // Calculate total and available (same logic as balance page)
      final total = transferred + current + bonus;
      final available = total - used;
      
            // Format vacation balance (same as balance page)
      final vacationBalanceText = available >= 0 
          ? '+${available.toStringAsFixed(1)}' 
          : available.toStringAsFixed(1);
      
      // For reporting purposes, also track time off requests
      // Note: totalVacationDays, totalSickDays, totalOtherTimeOff are already declared above
      
      for (final record in timeOffRecords) {
        final type = record['type']?.toString().toLowerCase() ?? '';
        final days = (record['totalWorkingDays'] as num?) ?? 0;
        final status = record['status']?.toString().toLowerCase() ?? '';
        
        if (status == 'approved') {
          if (type.contains('vacation') || type.contains('urlaub')) {
            totalVacationDays += _convertToDouble(days);
          } else if (type.contains('sick') || type.contains('krank')) {
            totalSickDays += _convertToDouble(days);
          } else {
            totalOtherTimeOff += _convertToDouble(days);
          }
        }
      }

      // Store user data
      _userReportData[userDoc.id] = {
        'userId': userDoc.id,
        'userName': userName,
        'totalSessions': userLogs.length,
        'totalTime': totalTime,
        'totalMinutes': totalMinutes,
        'totalExpenses': totalExpenses,
        'totalOvertime': totalOvertime,
        'totalOvertimeMinutes': totalOvertimeMinutes,
        'vacationBalance': vacationBalanceText,
        'totalVacationDays': totalVacationDays,
        'totalSickDays': totalSickDays,
        'totalOtherTimeOff': totalOtherTimeOff,
        'reportGenerated': DateTime.now(),
        'sessions': userLogs,
        'groupedSessions': _groupSessionsByTimePeriod(userLogs),
      };
      
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
