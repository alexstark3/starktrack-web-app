import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/calendar.dart';
import 'timeline_view.dart';

class TimeOffCalendar extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffCalendar({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TimeOffCalendar> createState() => _TimeOffCalendarState();
}

class _TimeOffCalendarState extends State<TimeOffCalendar> {
  String _selectedPeriod = 'Week';
  bool _showTeam = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final List<String> _periods = ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case 'Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
    }
  }

  void _resetToThisWeek() {
    setState(() {
      _selectedPeriod = 'Week';
      _updateDateRange();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateRange? result = await showDialog<DateRange>(
      context: context,
      builder: (context) => Dialog(
        child: CustomCalendar(
          initialDateRange: DateRange(startDate: _startDate, endDate: _endDate),
          onDateRangeChanged: (DateRange range) {
            // Update the date range immediately when user selects dates
            setState(() {
              _startDate = range.startDate ?? _startDate;
              _endDate = range.endDate ?? _endDate;
            });
          },
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
          showTodayIndicator: true,
        ),
      ),
    );

    // The date range is already updated in onDateRangeChanged
    // This is just for when user manually closes the dialog
    if (result != null && result.startDate != null) {
      setState(() {
        if (result.endDate != null) {
          _startDate = result.startDate!;
          _endDate = result.endDate!;
        } else {
          _startDate = result.startDate!;
          _endDate = result.startDate!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        // Filter Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16), // Equal padding all around
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Date Selection - Proper Calendar Widget
                    Expanded(
                      flex: 2, // Reduced from 3 to make it less wide
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colors.darkGray.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20, color: colors.darkGray),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                  style: TextStyle(
                                      color: colors.textColor, fontSize: 14),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  size: 16, color: colors.darkGray),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Period Dropdown - Fixed width to match content
                    Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Container(
                        height: 48, // Fixed height to match date field
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0), // Remove vertical padding
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: colors.darkGray.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: colors.darkGray, size: 16),
                            style: TextStyle(
                                color: colors.textColor, fontSize: 14),
                            items: _periods.map((String period) {
                              return DropdownMenuItem<String>(
                                value: period,
                                child: Text(period,
                                    style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPeriod = newValue;
                                  _updateDateRange();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reset Button
                    Container(
                      decoration: BoxDecoration(
                        color: colors.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _resetToThisWeek,
                        icon:
                            Icon(Icons.refresh, color: Colors.white, size: 20),
                        tooltip: 'Reset to this week',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Team Toggle - Squared buttons like other forms
                Row(
                  children: [
                    // Personal button - 120px width
                    SizedBox(
                      width: 120,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTeam = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showTeam
                                ? colors.primaryBlue
                                : colors.darkGray.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_showTeam
                                  ? colors.primaryBlue
                                  : colors.darkGray.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Personal',
                              style: TextStyle(
                                color:
                                    !_showTeam ? Colors.white : colors.darkGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Team button - 120px width
                    SizedBox(
                      width: 120,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTeam = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: _showTeam
                                ? colors.primaryBlue
                                : colors.darkGray.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showTeam
                                  ? colors.primaryBlue
                                  : colors.darkGray.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Team',
                              style: TextStyle(
                                color:
                                    _showTeam ? Colors.white : colors.darkGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Timeline View
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: IntrinsicHeight(
              child: _buildTimelineView(colors),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView(AppColors colors) {
    // For Year view, show all months of the current year
    if (_selectedPeriod == 'Year') {
      // Set the date range to cover the entire year
      final yearStart = DateTime(DateTime.now().year, 1, 1);
      final yearEnd = DateTime(DateTime.now().year, 12, 31);

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTeamMembers(),
        builder: (context, teamSnapshot) {
          if (!teamSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teamMembers = teamSnapshot.data!;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('timeoff_requests')
                .withConverter<Map<String, dynamic>>(
                  fromFirestore: (doc, _) => doc.data() ?? {},
                  toFirestore: (data, _) => data,
                )
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, timeOffSnapshot) {
              if (!timeOffSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final timeOffRequests = timeOffSnapshot.data!.docs;

              return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(widget.companyId)
                    .collection('timeoff_policies')
                    .withConverter<Map<String, dynamic>>(
                      fromFirestore: (doc, _) => doc.data() ?? {},
                      toFirestore: (data, _) => data,
                    )
                    .get(),
                builder: (context, policiesSnapshot) {
                  if (!policiesSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final policies = policiesSnapshot.data!.docs;
                  final policiesMap = <String, Map<String, dynamic>>{};
                  for (final policy in policies) {
                    final policyData = policy.data();
                    policiesMap[policyData['name'] as String] = policyData;
                  }

                  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(widget.companyId)
                        .collection('holiday_policies')
                        .withConverter<Map<String, dynamic>>(
                          fromFirestore: (doc, _) => doc.data() ?? {},
                          toFirestore: (data, _) => data,
                        )
                        .get(),
                    builder: (context, holidayPoliciesSnapshot) {
                      if (!holidayPoliciesSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final holidayPolicies =
                          holidayPoliciesSnapshot.data!.docs;
                      final holidayPoliciesMap =
                          <String, Map<String, dynamic>>{};
                      for (final policy in holidayPolicies) {
                        final policyData = policy.data();
                        holidayPoliciesMap[policyData['name'] as String] =
                            policyData;
                      }

                      return TimelineView(
                        weekStart: yearStart,
                        weekEnd: yearEnd,
                        teamMembers: teamMembers,
                        timeOffRequests: timeOffRequests,
                        policies: policiesMap,
                        holidayPolicies: holidayPoliciesMap,
                        colors: colors,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_requests')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (doc, _) => doc.data() ?? {},
            toFirestore: (data, _) => data,
          )
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading time off data',
                  style: TextStyle(color: colors.error, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: colors.darkGray, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final timeOffRequests = snapshot.data!.docs;

        // Filter requests for the selected date range
        final filteredRequests = timeOffRequests.where((doc) {
          final data = doc.data();
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();

          // Check if the request overlaps with the selected date range
          return startDate.isBefore(_endDate.add(const Duration(days: 1))) &&
              endDate.isAfter(_startDate.subtract(const Duration(days: 1)));
        }).toList();

        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('timeoff_policies')
              .withConverter<Map<String, dynamic>>(
                fromFirestore: (doc, _) => doc.data() ?? {},
                toFirestore: (data, _) => data,
              )
              .get(),
          builder: (context, policiesSnapshot) {
            if (!policiesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (policiesSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading policies',
                      style: TextStyle(color: colors.error, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${policiesSnapshot.error}',
                      style: TextStyle(color: colors.darkGray, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final policies = policiesSnapshot.data!.docs;

            // Create a map of policy names to policy data
            final policiesMap = <String, Map<String, dynamic>>{};
            for (final policy in policies) {
              final policyData = policy.data();
              policiesMap[policyData['name'] as String] = policyData;
            }

            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('holiday_policies')
                  .withConverter<Map<String, dynamic>>(
                    fromFirestore: (doc, _) => doc.data() ?? {},
                    toFirestore: (data, _) => data,
                  )
                  .get(),
              builder: (context, holidayPoliciesSnapshot) {
                if (!holidayPoliciesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (holidayPoliciesSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading holiday policies',
                          style: TextStyle(color: colors.error, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${holidayPoliciesSnapshot.error}',
                          style:
                              TextStyle(color: colors.darkGray, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final holidayPolicies = holidayPoliciesSnapshot.data!.docs;

                // Create a map of holiday policy data
                final holidayPoliciesMap = <String, Map<String, dynamic>>{};
                for (final policy in holidayPolicies) {
                  final policyData = policy.data();
                  holidayPoliciesMap[policyData['name'] as String] = policyData;
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getTeamMembers(),
                  builder: (context, teamSnapshot) {
                    if (!teamSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teamMembers = teamSnapshot.data!;

                    if (teamMembers.isEmpty) {
                      return const Center(child: Text('No team members found'));
                    }

                    // Use TimelineView for both Week and Month views
                    return TimelineView(
                      weekStart: _startDate,
                      weekEnd: _endDate,
                      teamMembers: teamMembers,
                      timeOffRequests: filteredRequests,
                      policies: policiesMap,
                      holidayPolicies: holidayPoliciesMap,
                      colors: colors,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getTeamMembers() {
    if (!_showTeam) {
      // Personal view - only show current user
      return FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (doc, _) => doc.data() ?? {},
            toFirestore: (data, _) => data,
          )
          .get()
          .then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          final name = data['name'] ??
              data['displayName'] ??
              data['firstName'] ??
              data['fullName'] ??
              data['userName'] ??
              'Unknown User';
          return [
            {
              'id': doc.id,
              'name': name,
              'lastName': data['surname'] ?? '',
              'email': data['email'] ?? '',
            }
          ];
        }
        return <Map<String, dynamic>>[];
      }).catchError((error) {
        return <Map<String, dynamic>>[];
      });
    }

    // Team view - fetch all team members with names
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (doc, _) => doc.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .get()
        .then((snapshot) {
      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        final name = data['name'] ??
            data['displayName'] ??
            data['firstName'] ??
            data['fullName'] ??
            data['userName'] ??
            'Unknown User';
        return {
          'id': doc.id,
          'name': name,
          'lastName': data['surname'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();
      return members;
    }).catchError((error) {
      return <Map<String, dynamic>>[];
    });
  }
}
