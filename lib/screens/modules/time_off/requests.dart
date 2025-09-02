import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/widgets/app_search_field.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/l10n/app_localizations.dart';

class TimeOffRequests extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffRequests(
      {super.key, required this.companyId, required this.userId});

  @override
  State<TimeOffRequests> createState() => _TimeOffRequestsState();
}

class _TimeOffRequestsState extends State<TimeOffRequests> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        // Search + New Request button row
        LayoutBuilder(
            builder: (context, constraints) {
              // Use Row for normal screens, Column for compact screens
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hintText: AppLocalizations.of(context)!.searchRequests,
                        onChanged: (v) =>
                            setState(() => _search = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _openNewRequestDialog(colors),
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.requestButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          foregroundColor: colors.whiteTextOnBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Compact mode - stack vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSearchField(
                      hintText: AppLocalizations.of(context)!.searchRequests,
                      onChanged: (v) =>
                          setState(() => _search = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _openNewRequestDialog(colors),
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.requestButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          foregroundColor: colors.whiteTextOnBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        // Standard 10px spacing between search and list
        const SizedBox(height: 10),
        // Requests list
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('timeoff_requests')
                .where('userId', isEqualTo: widget.userId)
                // Avoid composite-index requirement; client-side sort below
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        AppLocalizations.of(context)!.failedToLoadRequests));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Client-side sort by createdAt desc if present
              final docsList = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return tb.compareTo(ta);
                  }
                  return 0;
                });

              final docs = docsList.where((d) {
                if (_search.isEmpty) return true;
                final data = d.data();
                final hay = [
                  (data['policyName'] ?? '').toString(),
                  (data['status'] ?? '').toString(),
                  (data['description'] ?? '').toString(),
                ].join(' ').toLowerCase();
                return hay.contains(_search);
              }).toList();

              if (docs.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.noRequests));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
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
                      : end == null || end.isAtSameMomentAs(start)
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
                                  if (status == 'rejected') ...[
                                    _iconBtn(Icons.cancel, Colors.red, () {}, 'Rejected'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.edit, Theme.of(context).extension<AppColors>()!.primaryBlue, () => _editRejectedRequest(docs[index].reference, data), 'Edit'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.delete, Colors.red[300]!, () => _deleteRequest(docs[index].reference), 'Delete'),
                                  ] else if (status == 'pending') ...[
                                    _iconBtn(Icons.hourglass_empty, Colors.orange, () {}, 'Pending'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.edit, Theme.of(context).extension<AppColors>()!.primaryBlue, () => _editRequest(docs[index].reference, data), 'Edit'),
                                    const SizedBox(width: 8),
                                    _iconBtn(Icons.delete, Colors.red[300]!, () => _deleteRequest(docs[index].reference), 'Delete'),
                                  ] else if (status == 'approved') ...[
                                    if (data['isEdited'] == true) ...[
                                      _iconBtn(Icons.verified, Colors.orange, () {}, 'Edited'),
                                    ] else ...[
                                      _iconBtn(Icons.verified, Colors.green, () {}, 'Approved'),
                                    ],
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

  Widget _iconBtn(IconData icon, Color color, VoidCallback onPressed, String tooltip) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }



  Future<void> _openNewRequestDialog(AppColors colors) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewRequestDialog(
        companyId: widget.companyId,
        userId: widget.userId,
      ),
    );
  }

  Future<void> _editRequest(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
    // For pending requests, allow editing dates and description
    DateRange? range = DateRange(
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      startTime: data['startTime'] != null ? _parseTimeString(data['startTime']) : null,
      endTime: data['endTime'] != null ? _parseTimeString(data['endTime']) : null,
    );
    
    final DateRange? picked = await showDialog<DateRange>(
      context: context,
      builder: (context) => Dialog(
        child: CustomCalendar(
          initialDateRange: range,
          onDateRangeChanged: (r) => range = r,
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
          showTodayIndicator: true,
          showTime: data['policyType'] == 'Hours',
        ),
      ),
    );
    
    if (picked != null && picked.isComplete) {
      // Get user's working days configuration for accurate day calculation
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
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
      
      final type = data['type'] ?? 'vacation';
      
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
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _editRejectedRequest(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
    // For rejected requests, allow editing and resubmit
    DateRange? range = DateRange(
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      startTime: data['startTime'] != null ? _parseTimeString(data['startTime']) : null,
      endTime: data['endTime'] != null ? _parseTimeString(data['endTime']) : null,
    );
    
    final DateRange? picked = await showDialog<DateRange>(
      context: context,
      builder: (context) => Dialog(
        child: CustomCalendar(
          initialDateRange: range,
          onDateRangeChanged: (r) => range = r,
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
          showTodayIndicator: true,
          showTime: data['policyType'] == 'Hours',
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
          .doc(widget.userId)
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
      
      final type = data['type'] ?? 'vacation';
      
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
        'type': type,
        'status': 'pending', // Reset to pending for resubmission
        'reviewNote': null, // Clear rejection note
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _deleteRequest(DocumentReference<Map<String, dynamic>> ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return AlertDialog(
          title: const Text('Delete Request'),
          content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
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
        'deletedBy': widget.userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }
}

class _NewRequestDialog extends StatefulWidget {
  final String companyId;
  final String userId;
  const _NewRequestDialog({required this.companyId, required this.userId});

  @override
  State<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<_NewRequestDialog> {
  String? _selectedPolicyName;
  Map<String, dynamic>? _selectedPolicy;
  DateRange? _selectedRange;
  String _description = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.newTimeOffRequest,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor)),
            const SizedBox(height: 16),

            // Policy picker
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('timeoff_policies')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs
                    .map((d) => d.data())
                    .where((d) => (d['name'] as String?) != null)
                    .toList();
                items.sort((a, b) =>
                    (a['name'] as String).compareTo(b['name'] as String));

                return DropdownButtonFormField<String>(
                  initialValue: _selectedPolicyName,
                  items: items
                      .map((p) => DropdownMenuItem<String>(
                            value: p['name'] as String,
                            child: Text(p['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedPolicyName = v;
                      _selectedPolicy = items.firstWhere((p) => p['name'] == v);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.policy,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Calendar for date range (matches Time Off filter styling)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () async {
                  final DateRange? range = await showDialog<DateRange>(
                    context: context,
                    builder: (context) => Dialog(
                      child: CustomCalendar(
                        initialDateRange: _selectedRange,
                        onDateRangeChanged: (r) {
                          setState(() => _selectedRange = r);
                        },
                        minDate: DateTime(2020),
                        maxDate: DateTime(2030),
                        showTodayIndicator: true,
                        showTime: _selectedPolicy?['timeUnit'] == 'Hours', // Only enable time selection for Hours policies
                        companyId: widget.companyId, // Pass company ID to show approved requests
                      ),
                    ),
                  );
                  if (range != null) setState(() => _selectedRange = range);
                },
                child: IntrinsicHeight(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    constraints: const BoxConstraints(minHeight: 38),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.darkGray.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 20, color: colors.darkGray),
                        const SizedBox(width: 8),
                        Text(
                          _formattedRangeText(),
                          style:
                              TextStyle(color: colors.textColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionOptional,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (v) => _description = v.trim(),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.submitRequest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedPolicyName == null ||
        _selectedPolicy == null ||
        _selectedRange == null ||
        !_selectedRange!.isComplete) {
      return; // Could show a snackbar; keeping minimal per user preference
    }
    
    setState(() => _submitting = true);
    
    try {
      // Get user's working days configuration for accurate day calculation
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final userData = userDoc.data();
      final workingDays = userData?['workingDays'] as List<dynamic>? ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      final workingDaysList = workingDays.map((dayName) => dayName.toString()).toList();
      
      // Calculate working days and calendar days
      final totalWorkingDays = _selectedRange!.calculateWorkingDays(workingDaysList);
      final totalCalendarDays = _selectedRange!.endDate!.difference(_selectedRange!.startDate!).inDays + 1;
      final totalNonworkingDays = totalCalendarDays - totalWorkingDays;
      
      // Calculate total working hours based on time range
      double totalWorkingHours = 0.0;
      if (_selectedRange!.startTime != null && _selectedRange!.endTime != null) {
        // Calculate hours for each working day
        totalWorkingHours = totalWorkingDays * _calculateHoursBetweenTimes(
          _selectedRange!.startTime!, 
          _selectedRange!.endTime!
        );
      } else {
        // Full day (8 hours default)
        totalWorkingHours = totalWorkingDays * 8.0;
      }
      
      // Determine type from policy (default to 'vacation' if not specified)
      final type = _selectedPolicy!['type'] ?? 'vacation';
      
      // Create start and end DateTime with time if available
      DateTime startDateTime = _selectedRange!.startDate!;
      DateTime endDateTime = _selectedRange!.endDate!;
      
      if (_selectedRange!.startTime != null) {
        startDateTime = DateTime(
          startDateTime.year,
          startDateTime.month,
          startDateTime.day,
          _selectedRange!.startTime!.hour,
          _selectedRange!.startTime!.minute,
        );
      }
      
      if (_selectedRange!.endTime != null) {
        endDateTime = DateTime(
          endDateTime.year,
          endDateTime.month,
          endDateTime.day,
          _selectedRange!.endTime!.hour,
          _selectedRange!.endTime!.minute,
        );
      }
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_requests')
          .add({
        'userId': widget.userId,
        'policyName': _selectedPolicyName,
        'type': type,
        'totalCalendarDays': totalCalendarDays,
        'totalWorkingDays': totalWorkingDays,
        'totalNonworkingDays': totalNonworkingDays,
        'totalWorkingHours': totalWorkingHours,
        'status': 'pending',
        'startDate': Timestamp.fromDate(startDateTime),
        'endDate': Timestamp.fromDate(endDateTime),
        'description': _description,
        'approvedBy': null, // Will be set when approved
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _submitting = false);
      // Error creating time-off request
    }
  }
  
  /// Calculate hours between two times
  double _calculateHoursBetweenTimes(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final differenceMinutes = endMinutes - startMinutes;
    return differenceMinutes / 60.0;
  }
}

// Add the same method to _TimeOffRequestsState class
extension on _TimeOffRequestsState {
  /// Calculate hours between two times
  double _calculateHoursBetweenTimes(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final differenceMinutes = endMinutes - startMinutes;
    return differenceMinutes / 60.0;
  }
}

// Helper for date text formatting in the date field
extension on _NewRequestDialogState {
  String _formattedRangeText() {
    if (_selectedRange == null || !_selectedRange!.hasSelection) {
      return 'Pick dates';
    }
    final start = _selectedRange!.startDate;
    final end = _selectedRange!.endDate;
    if (start == null) return 'Pick dates';
    
    // Use European date format but include time if available
    String formatDateTime(DateTime date, TimeOfDay? time) {
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      if (time != null) {
        return '$dateStr ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      return dateStr;
    }
    
    if (end == null || start.isAtSameMomentAs(end)) {
      return formatDateTime(start, _selectedRange!.startTime);
    }
    return '${formatDateTime(start, _selectedRange!.startTime)} - ${formatDateTime(end, _selectedRange!.endTime)}';
  }
}
