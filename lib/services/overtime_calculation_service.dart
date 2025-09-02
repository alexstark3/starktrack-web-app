import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OvertimeCalculationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  /// Calculate overtime for a user based on their time logs
  static Future<Map<String, dynamic>> calculateOvertimeFromLogs(
    String companyId,
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Get user's weekly hours configuration
      final userDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {
          'transferred': 0,
          'current': 0,
          'bonus': 0,
          'used': 0,
          'calculationDetails': [],
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final weeklyHours =
          userData['weeklyHours'] ?? 40; // Default 40 hours per week
      
      // Get working days configuration
      final workingDays = userData['workingDays'] as List<dynamic>? ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      final workingDaysList = workingDays.map((dayName) {
        switch (dayName.toString()) {
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
      final dailyHours = weeklyHours / workingDaysList.length; // Calculate based on actual working days
      
      // Get overtime days configuration
      final overtimeDays = userData['overtimeDays'] as List<dynamic>? ?? ['Saturday', 'Sunday'];
      final overtimeDaysList = overtimeDays.isEmpty 
          ? <int>[] 
          : overtimeDays.map((dayName) {
              switch (dayName.toString()) {
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

      // Get user's start date (when they joined the company)
      final startDateString = userData['startDate'] as String?;
      DateTime? userStartDate;
      if (startDateString != null) {
        try {
          userStartDate = DateTime.parse(startDateString);
        } catch (e) {
          // Invalid startDate format; ignore and fallback to default
        }
      }

      // Use reasonable date range (last 4 weeks by default)
      final defaultFromDate = DateTime.now().subtract(const Duration(days: 28));
      final actualFromDate = fromDate ?? defaultFromDate;
      final actualToDate = toDate ?? DateTime.now();

      // Use the provided date range, but if no specific range is provided, use user's start date
      final effectiveFromDate = fromDate != null || toDate != null
          ? actualFromDate // Use provided date range
          : (userStartDate ??
              actualFromDate); // Use user start date only for default calculation

      // Get holidays for the company
      final holidays =
          await _getHolidays(companyId, effectiveFromDate, actualToDate);

      // Get paid holiday policies for the company in the given date range
      final paidHolidays = await _getPaidHolidayPolicies(
        companyId,
        effectiveFromDate,
        actualToDate,
      );

      // Get paid timeoff policies for the company in the given date range
      final paidTimeoffs = await _getPaidTimeoffPolicies(
        companyId,
        effectiveFromDate,
        actualToDate,
      );

      // Combine all worked time (holidays, paid holidays, paid timeoffs)
      final allWorkedTime = <String, int>{};

      // Add regular holidays as 8 hours each
      for (final holiday in holidays) {
        allWorkedTime[holiday] = 8 * 60; // 8 hours in minutes
      }

      // Add paid holidays and timeoffs
      allWorkedTime.addAll(paidHolidays);
      allWorkedTime.addAll(paidTimeoffs);

      // Build date range query
      Query logsQuery = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('sessionDate',
              isGreaterThanOrEqualTo:
                  DateFormat('yyyy-MM-dd').format(effectiveFromDate))
          .where('sessionDate',
              isLessThanOrEqualTo:
                  DateFormat('yyyy-MM-dd').format(actualToDate));

      final logsSnapshot = await logsQuery.get();
      final logs = logsSnapshot.docs;

      // Group logs by day
      Map<String, int> dailyMinutes = {};

      for (final logDoc in logs) {
        final logData = logDoc.data() as Map<String, dynamic>?;
        final sessionDate = logData?['sessionDate'] as String?;
        final durationMinutes = logData?['duration_minutes'] as int? ?? 0;

        if (sessionDate != null && durationMinutes > 0) {
          dailyMinutes[sessionDate] =
              (dailyMinutes[sessionDate] ?? 0) + durationMinutes;
        }
      }

      // Build full set of days to evaluate: all working days in range, plus any day
      // that has logs or paid time (holiday/timeoff). This ensures regular
      // workdays without logs contribute undertime.
      final df = DateFormat('yyyy-MM-dd');
      final Set<String> days = {};
      for (var d = effectiveFromDate;
          !d.isAfter(actualToDate);
          d = d.add(const Duration(days: 1))) {
        // Check if this day is a working day based on user configuration
        // workingDays now contains individual day numbers (1=Monday, 2=Tuesday, etc.)
        final workingDaysList = workingDays.map((dayName) {
          switch (dayName.toString()) {
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
        if (workingDaysList.contains(d.weekday)) {
          days.add(df.format(d));
        }
      }
      days.addAll(dailyMinutes.keys);
      days.addAll(allWorkedTime.keys);

      // Calculate overtime per day
      int totalOvertimeMinutes = 0;
      int totalWorkingDays = 0;
      List<Map<String, dynamic>> calculationDetails = [];

      for (final day in days) {
        final date = DateTime.parse(day);
        final minutesWorked = dailyMinutes[day] ?? 0;

        // Get paid time for this day (holidays, paid holidays, paid timeoffs)
        final paidMinutes = allWorkedTime[day] ?? 0;
        final totalMinutesForDay = minutesWorked + paidMinutes;

        // Check if it's a holiday
        final isHoliday = holidays.contains(day);

        // Check if it has paid time off
        final hasPaidTime = paidMinutes > 0;

        // Check if it's an overtime day based on user configuration
        final isOvertimeDay = overtimeDaysList.contains(date.weekday);

        Map<String, dynamic> dayDetail = {
          'date': day,
          'minutesWorked': minutesWorked,
          'hoursWorked': (minutesWorked / 60).toStringAsFixed(2),
          'paidMinutes': paidMinutes,
          'totalMinutes': totalMinutesForDay,
          'isHoliday': isHoliday,
          'isOvertimeDay': isOvertimeDay,
          'hasPaidTime': hasPaidTime,
          'overtimeMinutes': 0,
          'overtimeHours': '0.00',
          'reason': '',
        };

        if (isHoliday) {
          // Holiday: company gives 8h + worker work - expected 8h
          final expectedMinutes = (dailyHours * 60).round(); // 8h = 480 minutes
          final holidayOvertime = paidMinutes + minutesWorked - expectedMinutes;
          dayDetail['overtimeMinutes'] = holidayOvertime.toInt();
          dayDetail['overtimeHours'] = (holidayOvertime / 60).toStringAsFixed(2);
          dayDetail['reason'] = 'Holiday - company paid time + work - expected hours';
          totalOvertimeMinutes += holidayOvertime.toInt();

        } else if (!workingDaysList.contains(date.weekday) && minutesWorked > 0) {
          // Non-working day (weekend) with work - DOUBLE TIME (check this BEFORE overtime day)
          dayDetail['overtimeMinutes'] = minutesWorked * 2; // Double time
          dayDetail['overtimeHours'] = ((minutesWorked * 2) / 60).toStringAsFixed(2);
          dayDetail['reason'] = 'Non-working day (weekend) - double time overtime';
          totalOvertimeMinutes += (minutesWorked * 2); // Double time

        } else if (isOvertimeDay) {
          dayDetail['overtimeMinutes'] = minutesWorked;
          dayDetail['overtimeHours'] = (minutesWorked / 60).toStringAsFixed(2);
          dayDetail['reason'] = 'Overtime day - all time counts as overtime';
          totalOvertimeMinutes += minutesWorked;

        } else if (!workingDaysList.contains(date.weekday)) {
          // Non-working day (weekend) with no work - no overtime
          dayDetail['reason'] = 'Non-working day (weekend) - no work';

        } else {
          // Regular working day
          totalWorkingDays++;
          final expectedMinutes = (dailyHours * 60).round();
          final dayOvertime = totalMinutesForDay - expectedMinutes; // Use total minutes including paid time

          dayDetail['expectedMinutes'] = expectedMinutes;
          dayDetail['expectedHours'] = (expectedMinutes / 60).toStringAsFixed(2);

          if (dayOvertime > 0) {
            // Overtime - worked more than expected (including paid time)
            dayDetail['overtimeMinutes'] = dayOvertime.toInt();
            dayDetail['overtimeHours'] = (dayOvertime / 60).toStringAsFixed(2);
            dayDetail['reason'] = hasPaidTime
                ? 'Regular day with paid time off - overtime calculated'
                : 'Regular day - overtime calculated';
            totalOvertimeMinutes += dayOvertime.toInt();

          } else if (dayOvertime < 0) {
            // Undertime - worked less than expected
            dayDetail['overtimeMinutes'] = dayOvertime.toInt();
            dayDetail['overtimeHours'] = (dayOvertime / 60).toStringAsFixed(2);
            dayDetail['reason'] = hasPaidTime
                ? 'Regular day with paid time off - undertime calculated'
                : 'Regular day - undertime calculated';
            totalOvertimeMinutes += dayOvertime.toInt(); // This will subtract from total

          } else {
            // Exactly expected hours
            dayDetail['reason'] = hasPaidTime
                ? 'Regular day with paid time off - no overtime/undertime'
                : 'Regular day - no overtime/undertime';

          }
        }

        calculationDetails.add(dayDetail);
      }

      // Cap overtime at reasonable amount (max 20 hours per week)
      final maxOvertimePerWeek = 20 * 60; // 20 hours in minutes
      final maxTotalOvertime = maxOvertimePerWeek * 4; // 4 weeks
      if (totalOvertimeMinutes > maxTotalOvertime) {
        totalOvertimeMinutes = maxTotalOvertime;
      }

      // Get existing overtime data (for transferred and bonus)
      final existingOvertimeData = userData['overtime'] ?? {};
      final transferred =
          _convertToMinutes(existingOvertimeData['transferred'] ?? 0);
      final bonus = _convertToMinutes(existingOvertimeData['bonus'] ?? 0);
      final used = _convertToMinutes(existingOvertimeData['used'] ?? 0);

      final result = {
        'transferred': transferred,
        'current': totalOvertimeMinutes,
        'bonus': bonus,
        'used': used,
        'calculationDetails': calculationDetails,
        'summary': {
          'totalWorkingDays': totalWorkingDays,
          'totalOvertimeMinutes': totalOvertimeMinutes,
          'totalOvertimeHours': (totalOvertimeMinutes / 60).toStringAsFixed(2),
          'holidaysFound': holidays.length,
          'logsProcessed': logs.length,
        },
      };

      return result;
    } catch (e) {
      return {
        'transferred': 0,
        'current': 0,
        'bonus': 0,
        'used': 0,
        'calculationDetails': [],
      };
    }
  }

  /// Get holidays for the company in the given date range
  static Future<Set<String>> _getHolidays(
    String companyId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      final policiesSnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('holiday_policies')
          .get();

      final holidays = <String>{};
      
      for (final doc in policiesSnapshot.docs) {
        final data = doc.data();
        
        final period = data['period'] as Map<String, dynamic>?;
        final startTimestamp = period?['start'] as Timestamp?;
        final endTimestamp = period?['end'] as Timestamp?;
        final repeatAnnually = data['repeatAnnually'] ?? false;

        if (startTimestamp != null && endTimestamp != null) {
          final startDate = startTimestamp.toDate();
          final endDate = endTimestamp.toDate();



          // Check if this policy applies to the date range
          if (repeatAnnually) {
            // For annual repeating policies, check each year in the range
            for (int year = fromDate.year; year <= toDate.year; year++) {
              final yearStart = DateTime(year, startDate.month, startDate.day);
              final yearEnd = DateTime(year, endDate.month, endDate.day);

              if (yearStart.isBefore(toDate.add(Duration(days: 1))) && yearEnd.isAfter(fromDate.subtract(Duration(days: 1)))) {
                // Policy applies to this year, add all days in the range
                final effectiveStart = yearStart.isAfter(fromDate) ? yearStart : fromDate;
                final effectiveEnd = yearEnd.isBefore(toDate) ? yearEnd : toDate;

                for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                  final dayDate = effectiveStart.add(Duration(days: i));
                  final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
                  holidays.add(dayKey);
                }
              }
            }
          } else {
            // Non-repeating policy, check if it overlaps with the date range
            if (startDate.isBefore(toDate.add(Duration(days: 1))) && endDate.isAfter(fromDate.subtract(Duration(days: 1)))) {
              final effectiveStart = startDate.isAfter(fromDate) ? startDate : fromDate;
              final effectiveEnd = endDate.isBefore(toDate) ? endDate : toDate;

              for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                final dayDate = effectiveStart.add(Duration(days: i));
                final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
                holidays.add(dayKey);
              }
            }
          }
        }
      }


      return holidays;
    } catch (e) {
      return <String>{};
    }
  }

  /// Get paid holiday policies for the company in the given date range
  static Future<Map<String, int>> _getPaidHolidayPolicies(
    String companyId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      final policiesSnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('holiday_policies')
          .where('paid', isEqualTo: true)
          .get();

      final paidDays = <String, int>{};

      for (final doc in policiesSnapshot.docs) {
        final data = doc.data();
        final period = data['period'] as Map<String, dynamic>?;
        final startTimestamp = period?['start'] as Timestamp?;
        final endTimestamp = period?['end'] as Timestamp?;
        final repeatAnnually = data['repeatAnnually'] ?? false;

        if (startTimestamp != null && endTimestamp != null) {
          final startDate = startTimestamp.toDate();
          final endDate = endTimestamp.toDate();

          // Check if this policy applies to the date range
          if (repeatAnnually) {
            // For annual repeating policies, check each year in the range
            for (int year = fromDate.year; year <= toDate.year; year++) {
              final yearStart = DateTime(year, startDate.month, startDate.day);
              final yearEnd = DateTime(year, endDate.month, endDate.day);

              if (yearStart.isBefore(toDate) && yearEnd.isAfter(fromDate)) {
                // Policy applies to this year, add all days in the range
                final effectiveStart =
                    yearStart.isAfter(fromDate) ? yearStart : fromDate;
                final effectiveEnd =
                    yearEnd.isBefore(toDate) ? yearEnd : toDate;

                for (int i = 0;
                    i <= effectiveEnd.difference(effectiveStart).inDays;
                    i++) {
                  final dayDate = effectiveStart.add(Duration(days: i));
                  final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
                  paidDays[dayKey] =
                      8 * 60; // 8 hours in minutes for paid holidays
                }
              }
            }
          } else {
            // Non-repeating policy, check if it overlaps with the date range
            if (startDate.isBefore(toDate) && endDate.isAfter(fromDate)) {
              final effectiveStart =
                  startDate.isAfter(fromDate) ? startDate : fromDate;
              final effectiveEnd = endDate.isBefore(toDate) ? endDate : toDate;

              for (int i = 0;
                  i <= effectiveEnd.difference(effectiveStart).inDays;
                  i++) {
                final dayDate = effectiveStart.add(Duration(days: i));
                final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
                paidDays[dayKey] =
                    8 * 60; // 8 hours in minutes for paid holidays
              }
            }
          }
        }
      }

      return paidDays;
    } catch (e) {
      return <String, int>{};
    }
  }

  /// Get paid timeoff policies for the company in the given date range
  static Future<Map<String, int>> _getPaidTimeoffPolicies(
    String companyId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      final policiesSnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('timeoff_policies')
          .where('paid', isEqualTo: true)
          .get();

      final paidDays = <String, int>{};

      for (final doc in policiesSnapshot.docs) {
        final data = doc.data();
        final period = data['period'] as Map<String, dynamic>?;
        final startTimestamp = period?['start'] as Timestamp?;
        final endTimestamp = period?['end'] as Timestamp?;
        final repeatAnnually = data['repeatAnnually'] ?? false;
        final timeUnit = data['timeUnit'] ?? 'Days';
        final accruingAmount = (data['accruingAmount'] ?? 1.0) as double;

        if (startTimestamp != null && endTimestamp != null) {
          final startDate = startTimestamp.toDate();
          final endDate = endTimestamp.toDate();

          // Check if this policy applies to the date range
          if (repeatAnnually) {
            // For annual repeating policies, check each year in the range
            for (int year = fromDate.year; year <= toDate.year; year++) {
              final yearStart = DateTime(year, startDate.month, startDate.day);
              final yearEnd = DateTime(year, endDate.month, endDate.day);

              if (yearStart.isBefore(toDate) && yearEnd.isAfter(fromDate)) {
                // Policy applies to this year, add all days in the range
                final effectiveStart =
                    yearStart.isAfter(fromDate) ? yearStart : fromDate;
                final effectiveEnd =
                    yearEnd.isBefore(toDate) ? yearEnd : toDate;

                for (int i = 0;
                    i <= effectiveEnd.difference(effectiveStart).inDays;
                    i++) {
                  final dayDate = effectiveStart.add(Duration(days: i));
                  final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);

                  // Convert to minutes based on time unit
                  final minutes = timeUnit == 'Hours'
                      ? (accruingAmount * 60).round()
                      : (accruingAmount * 8 * 60).round(); // 8 hours per day

                  paidDays[dayKey] = minutes;
                }
              }
            }
          } else {
            // Non-repeating policy, check if it overlaps with the date range
            if (startDate.isBefore(toDate) && endDate.isAfter(fromDate)) {
              final effectiveStart =
                  startDate.isAfter(fromDate) ? startDate : fromDate;
              final effectiveEnd = endDate.isBefore(toDate) ? endDate : toDate;

              for (int i = 0;
                  i <= effectiveEnd.difference(effectiveStart).inDays;
                  i++) {
                final dayDate = effectiveStart.add(Duration(days: i));
                final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);

                // Convert to minutes based on time unit
                final minutes = timeUnit == 'Hours'
                    ? (accruingAmount * 60).round()
                    : (accruingAmount * 8 * 60).round(); // 8 hours per day

                paidDays[dayKey] = minutes;
              }
            }
          }
        }
      }

      return paidDays;
    } catch (e) {
      return <String, int>{};
    }
  }

  /// Convert value to minutes
  static int _convertToMinutes(dynamic value) {
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

  /// Update overtime data in user document
  static Future<void> updateOvertimeData(
    String companyId,
    String userId,
    Map<String, int> overtimeData,
  ) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .update({
        'overtime': overtimeData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate and update overtime for a user
  static Future<void> calculateAndUpdateOvertime(
    String companyId,
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final overtimeData = await calculateOvertimeFromLogs(
        companyId,
        userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Extract only the overtime values for storage
      final overtimeValues = {
        'transferred': overtimeData['transferred'] as int,
        'current': overtimeData['current'] as int,
        'bonus': overtimeData['bonus'] as int,
        'used': overtimeData['used'] as int,
      };

      await updateOvertimeData(companyId, userId, overtimeValues);
    } catch (e) {
      rethrow;
    }
  }
}
