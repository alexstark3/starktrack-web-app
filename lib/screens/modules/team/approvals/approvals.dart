import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/l10n/app_localizations.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/widgets/app_search_field.dart';
import 'package:starktrack/utils/app_logger.dart';

class TeamApprovalsScreen extends StatefulWidget {
  final String companyId;
  const TeamApprovalsScreen({super.key, required this.companyId});

  @override
  State<TeamApprovalsScreen> createState() => _TeamApprovalsScreenState();
}

class _TeamApprovalsScreenState extends State<TeamApprovalsScreen> {
  String _search = '';
  String _statusFilter = 'all'; // default to all

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              // Search (standardized single field without extra wrapper borders)
              Expanded(
                child: AppSearchField(
                  hintText: AppLocalizations.of(context)!.searchRequests,
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 10),
              // Status filter
              SizedBox(
                height: 38,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      items: [
                        DropdownMenuItem(
                            value: 'pending',
                            child: Text(AppLocalizations.of(context)!.pending)),
                        DropdownMenuItem(
                            value: 'approved',
                            child:
                                Text(AppLocalizations.of(context)!.approved)),
                        DropdownMenuItem(
                            value: 'rejected',
                            child:
                                Text(AppLocalizations.of(context)!.rejected)),
                        DropdownMenuItem(
                            value: 'all',
                            child: Text(AppLocalizations.of(context)!.all)),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('timeoff_requests')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.error));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs.where((d) {
                final data = d.data();
                final status = (data['status'] ?? 'pending').toString();
                if (_statusFilter != 'all' && status != _statusFilter) {
                  return false;
                }
                if (_search.isEmpty) {
                  return true;
                }
                final hay = [
                  (data['policyName'] ?? '').toString(),
                  status,
                  (data['description'] ?? '').toString(),
                  (data['userId'] ?? '').toString(),
                ].join(' ').toLowerCase();
                return hay.contains(_search);
              }).toList()
                ..sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return tb.compareTo(ta);
                  }
                  return 0;
                });

              if (docs.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.noRequests));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final ref = docs[i].reference;
                  final data = docs[i].data();
                  final start = (data['startDate'] as Timestamp?)?.toDate();
                  final end = (data['endDate'] as Timestamp?)?.toDate();
                  final status = (data['status'] ?? 'pending') as String;
                  
                  // Format date with time for half-day selections
                  String formatDateTime(DateTime date, String? timeStr) {
                    final dateStr = DateFormat('dd/MM/yyyy').format(date);
                    if (timeStr != null && timeStr.isNotEmpty) {
                      return '$dateStr $timeStr';
                    }
                    return dateStr;
                  }

                  final startTime = data['startTime'] as String?;
                  final endTime = data['endTime'] as String?;
                  
                  final dateText = start == null
                      ? ''
                      : end == null || start.isAtSameMomentAs(end)
                          ? formatDateTime(start, startTime)
                          : '${formatDateTime(start, startTime)} - ${formatDateTime(end, endTime)}';

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['policyName'] ?? AppLocalizations.of(context)!.unknownPolicy,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateText,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),

                              if (data['reviewNote'] != null && data['reviewNote'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.note,
                                      size: 12,
                                      color: Colors.red[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['reviewNote'],
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Action buttons below the request details (moved from right side)
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (status == 'pending') ...[
                                    _iconBtn(Icons.check, Colors.green, () => _updateStatus(ref, 'approved'), 'Approve'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.edit, Theme.of(context).extension<AppColors>()!.primaryBlue, () => _editDates(ref, start, end), 'Edit'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.cancel, Colors.red, () => _denyWithNote(ref), 'Deny'),
                                  ] else if (status == 'approved') ...[
                                    if (data['isEdited'] == true) ...[
                                      _iconBtn(Icons.verified, Colors.orange, () {}, 'Edited'),
                                    ] else ...[
                                      _iconBtn(Icons.verified, Colors.green, () {}, 'Approved'),
                                    ],
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.edit, Theme.of(context).extension<AppColors>()!.primaryBlue, () => _editDates(ref, start, end), 'Edit'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.delete, Colors.red[300]!, () => _deleteRequest(ref), 'Delete'),
                                  ] else if (status == 'rejected') ...[
                                    _iconBtn(Icons.cancel, Colors.red, () {}, 'Rejected'),
                                  ] else if (status == 'deleted') ...[
                                    _iconBtn(Icons.delete, Colors.grey, () {}, 'Deleted'),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),


                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }



  /// Get holidays for the company in the given date range
  Future<Set<String>> _getHolidays(String companyId, DateTime fromDate, DateTime toDate) async {
    try {
      final holidaysSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('holidays')
          .where('date', isGreaterThanOrEqualTo: '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}')
          .where('date', isLessThanOrEqualTo: '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}')
          .get();

      final holidays = <String>{};
      for (final doc in holidaysSnapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        if (date != null) {
          holidays.add(date);
        }
      }
      return holidays;
    } catch (e) {
      return <String>{};
    }
  }

  /// Get paid holiday policies for the company in the given date range
  Future<Map<String, int>> _getPaidHolidayPolicies(String companyId, DateTime fromDate, DateTime toDate) async {
    try {
      final policiesSnapshot = await FirebaseFirestore.instance
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

          if (repeatAnnually) {
            // For annual repeating policies, check each year in the range
            for (int year = fromDate.year; year <= toDate.year; year++) {
              final yearStart = DateTime(year, startDate.month, startDate.day);
              final yearEnd = DateTime(year, endDate.month, endDate.day);

              if (yearStart.isBefore(toDate) && yearEnd.isAfter(fromDate)) {
                final effectiveStart = yearStart.isAfter(fromDate) ? yearStart : fromDate;
                final effectiveEnd = yearEnd.isBefore(toDate) ? yearEnd : toDate;

                for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                  final dayDate = effectiveStart.add(Duration(days: i));
                  final dayKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
                  paidDays[dayKey] = 1; // Mark as paid day
                }
              }
            }
          } else {
            // Non-repeating policy
            if (startDate.isBefore(toDate) && endDate.isAfter(fromDate)) {
              final effectiveStart = startDate.isAfter(fromDate) ? startDate : fromDate;
              final effectiveEnd = endDate.isBefore(toDate) ? endDate : toDate;

              for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                final dayDate = effectiveStart.add(Duration(days: i));
                final dayKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
                paidDays[dayKey] = 1; // Mark as paid day
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

  /// Get time-off policies for the company in the given date range
  Future<Map<String, Map<String, dynamic>>> _getTimeOffPolicies(String companyId, DateTime fromDate, DateTime toDate) async {
    try {
      final policiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('timeoff_policies')
          .get();

      final policies = <String, Map<String, dynamic>>{};
      for (final doc in policiesSnapshot.docs) {
        final data = doc.data();
        final period = data['period'] as Map<String, dynamic>?;
        final startTimestamp = period?['start'] as Timestamp?;
        final endTimestamp = period?['end'] as Timestamp?;
        final repeatAnnually = data['repeatAnnually'] ?? false;
        final doesNotCount = data['doesNotCount'] ?? false;

        if (startTimestamp != null && endTimestamp != null) {
          final startDate = startTimestamp.toDate();
          final endDate = endTimestamp.toDate();

          if (repeatAnnually) {
            // For annual repeating policies, check each year in the range
            for (int year = fromDate.year; year <= toDate.year; year++) {
              final yearStart = DateTime(year, startDate.month, startDate.day);
              final yearEnd = DateTime(year, endDate.month, endDate.day);

              if (yearStart.isBefore(toDate) && yearEnd.isAfter(fromDate)) {
                final effectiveStart = yearStart.isAfter(fromDate) ? yearStart : fromDate;
                final effectiveEnd = yearEnd.isBefore(toDate) ? yearEnd : toDate;

                for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                  final dayDate = effectiveStart.add(Duration(days: i));
                  final dayKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
                  policies[dayKey] = {
                    'doesNotCount': doesNotCount,
                    'name': data['name'] ?? 'Unknown Policy',
                  };
                }
              }
            }
          } else {
            // Non-repeating policy
            if (startDate.isBefore(toDate) && endDate.isAfter(fromDate)) {
              final effectiveStart = startDate.isAfter(fromDate) ? startDate : fromDate;
              final effectiveEnd = endDate.isBefore(toDate) ? endDate : toDate;

              for (int i = 0; i <= effectiveEnd.difference(effectiveStart).inDays; i++) {
                final dayDate = effectiveStart.add(Duration(days: i));
                final dayKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
                policies[dayKey] = {
                  'doesNotCount': doesNotCount,
                  'name': data['name'] ?? 'Unknown Policy',
                };
              }
            }
          }
        }
      }
      return policies;
    } catch (e) {
      return <String, Map<String, dynamic>>{};
    }
  }

  /// Check if a day should be excluded from vacation calculation based on time-off policies
  bool _isExcludedByTimeOffPolicy(String dateKey, Map<String, Map<String, dynamic>> policies, String requestType) {
    final policy = policies[dateKey];
    if (policy == null) return false;
    
    // If the policy says "does not count", exclude it
    if (policy['doesNotCount'] == true) {
      return true;
    }
    
    // You can add more logic here for specific policy types
    // For example, if it's a sick leave policy and the request is vacation
    return false;
  }

  Future<void> _updateStatus(
      DocumentReference<Map<String, dynamic>> ref, String status) async {
    // Get current user ID for approvedBy field
    final currentUser = FirebaseAuth.instance.currentUser;
    final approvedBy = currentUser?.uid ?? 'unknown';
    
    // Update the time-off request status
    await ref.update({
      'status': status, 
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'approved') 'approvedBy': approvedBy,
    });
    
    // If approved, update the user's vacation balance
    if (status == 'approved') {
      try {
        // Get the time-off request data
        final requestData = await ref.get();
        final data = requestData.data();
        
        if (data != null) {
          final userId = data['userId'] as String?;
          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          final type = data['type']?.toString().toLowerCase() ?? '';
          final days = (data['totalWorkingDays'] as num?) ?? 0;
          
          // Only update for vacation types
          if (userId != null && 
              (type.contains('vacation') || type.contains('urlaub')) &&
              startDate != null && endDate != null) {
            
            // Get user's working days configuration for accurate day calculation
            final userDoc = await FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('users')
                .doc(userId)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data();
              final workingDaysStr = userData?['workingDays']?.toString() ?? 'Monday,Tuesday,Wednesday,Thursday,Friday';
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
              // Calculate ONLY working days (exclude weekends, holidays, and non-working days)
              int workingDaysCount = 0;
              
              // Get company holidays and policies for this date range
              final holidays = await _getHolidays(widget.companyId, startDate, endDate);
              final paidHolidays = await _getPaidHolidayPolicies(widget.companyId, startDate, endDate);
              final timeOffPolicies = await _getTimeOffPolicies(widget.companyId, startDate, endDate);
              
              for (DateTime date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                
                if (workingDaysList.contains(date.weekday)) {
                  // Check if this day is excluded from vacation calculation
                                    if (holidays.contains(dateKey) || 
                      paidHolidays.containsKey(dateKey) ||
                      _isExcludedByTimeOffPolicy(dateKey, timeOffPolicies, type)) {
                    // Day excluded from vacation calculation
                  } else {
                    workingDaysCount++;
                  }
          }
        }
        
        // Use days directly if provided, otherwise use calculated working days
        final daysToDeduct = days > 0 ? days : workingDaysCount.toDouble();
        
        // Update user's annualLeaveDays.used field
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userId)
            .update({
          'annualLeaveDays.used': FieldValue.increment(daysToDeduct),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Vacation balance updated successfully
            }
          }
        }
      } catch (e) {
        // Don't fail the approval if balance update fails
        AppLogger.error('Error updating vacation balance: $e');
      }
    }
  }

  Future<void> _editDates(DocumentReference<Map<String, dynamic>> ref,
      DateTime? start, DateTime? end) async {
    if (!mounted) return;
    
    // Get the current request data to extract times
    final requestData = await ref.get();
    final data = requestData.data();
    
    // Parse the stored times
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    
    if (data != null) {
      if (data['startTime'] != null) {
        final timeStr = data['startTime'] as String;
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          startTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
      
      if (data['endTime'] != null) {
        final timeStr = data['endTime'] as String;
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          endTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
    
    DateRange? range = DateRange(
      startDate: start, 
      endDate: end,
      startTime: startTime,
      endTime: endTime,
    );
    
    if (!mounted) return;
    final DateRange? picked = await showDialog<DateRange>(
      context: context,
      builder: (context) => Dialog(
        child: CustomCalendar(
          initialDateRange: range,
          onDateRangeChanged: (r) => range = r,
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
          showTodayIndicator: true,
          showTime: true, // Enable time selection for editing
          companyId: widget.companyId, // Pass company ID to show approved requests
        ),
      ),
    );
    
    if (picked != null && picked.isComplete) {
      // Get user's working days configuration for accurate day calculation
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      
      final userData = userDoc.data();
      final workingDays = userData?['workingDays'] as List<dynamic>? ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      final workingDaysList = workingDays.map((dayName) => dayName.toString()).toList();
      
      // Calculate working days and calendar days
      final totalWorkingDays = picked.calculateWorkingDays(workingDaysList);
      final totalCalendarDays = picked.endDate!.difference(picked.startDate!).inDays + 1;
      final totalNonworkingDays = totalCalendarDays - totalWorkingDays;
      
      // Calculate total working hours based on time range
      double totalWorkingHours = 0.0;
      if (picked.startTime != null && picked.endTime != null) {
        // Calculate hours for each working day
        totalWorkingHours = totalWorkingDays * _calculateHoursBetweenTimes(
          picked.startTime!, 
          picked.endTime!
        );
      } else {
        // Full day (8 hours default)
        totalWorkingHours = totalWorkingDays * 8.0;
      }
      
      // Create start and end DateTime with time if available
      DateTime startDateTime = picked.startDate!;
      DateTime endDateTime = picked.endDate!;
      
      if (picked.startTime != null) {
        startDateTime = DateTime(
          startDateTime.year,
          startDateTime.month,
          startDateTime.day,
          picked.startTime!.hour,
          picked.startTime!.minute,
        );
      }
      
      if (picked.endTime != null) {
        endDateTime = DateTime(
          endDateTime.year,
          endDateTime.month,
          endDateTime.day,
          picked.endTime!.hour,
          picked.endTime!.minute,
        );
      }
      
      await ref.update({
        'startDate': Timestamp.fromDate(startDateTime),
        'endDate': Timestamp.fromDate(endDateTime),
        'totalCalendarDays': totalCalendarDays,
        'totalWorkingDays': totalWorkingDays,
        'totalNonworkingDays': totalNonworkingDays,
        'totalWorkingHours': totalWorkingHours,
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': FirebaseAuth.instance.currentUser?.uid,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _deleteRequest(
      DocumentReference<Map<String, dynamic>> ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return AlertDialog(
          title: Text('Delete Request'),
          content: const Text('Are you sure you want to delete this approved request? This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            )
          ],
        );
      },
    );
    if (ok == true) {
      await ref.update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _denyWithNote(
      DocumentReference<Map<String, dynamic>> ref) async {
    final TextEditingController ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.denyRequest),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.descriptionOptional),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.red, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.deny),
            )
          ],
        );
      },
    );
    if (ok == true) {
      await ref.update({
        'status': 'rejected',
        'reviewNote': ctrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onPressed, String tooltip) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  /// Calculate hours between two times
  double _calculateHoursBetweenTimes(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final differenceMinutes = endMinutes - startMinutes;
    return differenceMinutes / 60.0;
  }
}


