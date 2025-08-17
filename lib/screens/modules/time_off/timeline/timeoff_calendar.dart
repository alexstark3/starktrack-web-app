import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/calendar.dart';
import 'timeline_view.dart';
import '../../../../l10n/app_localizations.dart';

class TimeOffCalendar extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffCalendar({
    super.key,
    required this.companyId,
    required this.userId,
  });

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

  // Helper function to format date range with smart wrapping
  String _formatDateRange(DateTime startDate, DateTime endDate, bool isCompact) {
    if (isCompact) {
      return '${DateFormat('dd/MM/yyyy').format(startDate)}\n${DateFormat('dd/MM/yyyy').format(endDate)}';
    } else {
      return '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
    }
  }

  // Helper function to determine if dates should wrap based on available width
  bool _shouldWrapDates(double availableWidth) {
    // Only wrap when space is very tight (below 400px for the date field)
    // This ensures dates stay on one line unless absolutely necessary
    return availableWidth < 400;
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
        // Date Selection and Controls
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection and Controls - Wrap gracefully only when needed
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if we need to wrap based on available width
                final availableWidth = constraints.maxWidth;
                // More intelligent wrapping: only wrap when space is actually tight
                // This ensures the layout stays clean unless absolutely necessary
                final needsWrap = availableWidth < 500; // Reduced breakpoint for better UX

                if (needsWrap) {
                  // Compact mode - use Wrap for responsive layout
                  return Wrap(
                    spacing: 10, // 10px spacing between elements on the same line
                    runSpacing: 10, // 10px spacing between lines when wrapping
                    alignment: WrapAlignment.start, // Ensure elements start from left
                    crossAxisAlignment: WrapCrossAlignment.start, // Align elements to top
                    children: [
                      // Date Selection - Proper Calendar Widget (full width in compact mode)
                      SizedBox(
                        width: availableWidth, // Take full available width
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, // Reduced from 18 to 10px
                                vertical: 9), // Center content vertically in 38px height
                            constraints: BoxConstraints(
                              minHeight: 38, // Minimum height
                              maxHeight: _shouldWrapDates(availableWidth) ? 60 : 38, // Only expand height when wrapping is needed
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.darkGray.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(9), // Match history page radius
                            ),
                            child: Row(
                              // Change back to Row for proper layout
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 20, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    // Left align the text instead of center
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatDateRange(_startDate, _endDate, _shouldWrapDates(availableWidth)),
                                      style: TextStyle(
                                          color: colors.textColor,
                                          fontSize: 16), // Match history page font size
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: _shouldWrapDates(availableWidth) ? 2 : 1, // Only wrap when necessary
                                    ),
                                  ),
                                ),
                                // Removed the dropdown arrow icon
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Period Dropdown - Fixed width to match content
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Container(
                          height: 38, // Match history page filter height
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0), // Match history page padding
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colors.darkGray.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(9), // Match history page radius
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: colors.darkGray, size: 22), // Match history page icon size
                              style: TextStyle(
                                  color: colors.textColor, fontSize: 16), // Match history page font size
                              items: _periods.map((String period) {
                                return DropdownMenuItem<String>(
                                  value: period,
                                  child: Text(
                                      period == 'Week'
                                          ? AppLocalizations.of(context)!.week
                                          : period == 'Month'
                                              ? AppLocalizations.of(context)!.month
                                              : AppLocalizations.of(context)!.year,
                                      style: TextStyle(fontSize: 16)), // Match history page font size
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
                      // Reset Button
                      Container(
                        height: 38, // Match history page filter height
                        decoration: BoxDecoration(
                          color: colors.primaryBlue,
                          borderRadius: BorderRadius.circular(9), // Match history page radius
                        ),
                        child: IconButton(
                          onPressed: _resetToThisWeek,
                          icon: Icon(Icons.refresh,
                              color: Colors.white, size: 24), // Match history page icon size
                          tooltip: AppLocalizations.of(context)!.resetToThisWeek,
                          padding: EdgeInsets.zero, // Remove default padding to fit 38px height
                          constraints: const BoxConstraints(
                              minWidth: 38, minHeight: 38), // Ensure proper sizing
                        ),
                      ),
                    ],
                  );
                } else {
                  // Full mode - use Row for single-line layout
                  return Row(
                    children: [
                      // Date Selection - Proper Calendar Widget
                      Expanded(
                        flex: 2, // Reduced from 3 to make it less wide
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, // Reduced from 18 to 10px
                                vertical: 9), // Center content vertically in 38px height
                            height: _shouldWrapDates(availableWidth) ? 60 : 38, // Dynamic height based on wrapping needs
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.darkGray.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(9), // Match history page radius
                            ),
                            child: Row(
                              // Change back to Row for proper layout
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 20, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    // Left align the text instead of center
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatDateRange(_startDate, _endDate, _shouldWrapDates(availableWidth)),
                                      style: TextStyle(
                                          color: colors.textColor,
                                          fontSize: 16), // Match history page font size
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: _shouldWrapDates(availableWidth) ? 2 : 1, // Only wrap when necessary
                                    ),
                                  ),
                                ),
                                // Removed the dropdown arrow icon
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Changed from 8 to 10px to match new spacing
                      // Period Dropdown - Fixed width to match content
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Container(
                          height: 38, // Match history page filter height
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0), // Match history page padding
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colors.darkGray.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(9), // Match history page radius
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: colors.darkGray, size: 22), // Match history page icon size
                              style: TextStyle(
                                  color: colors.textColor, fontSize: 16), // Match history page font size
                              items: _periods.map((String period) {
                                return DropdownMenuItem<String>(
                                  value: period,
                                  child: Text(
                                      period == 'Week'
                                          ? AppLocalizations.of(context)!.week
                                          : period == 'Month'
                                              ? AppLocalizations.of(context)!.month
                                              : AppLocalizations.of(context)!.year,
                                      style: TextStyle(fontSize: 16)), // Match history page font size
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
                      const SizedBox(width: 8), // Match history page spacing
                      // Reset Button
                      SizedBox(
                        height: 38, // Match history page filter height
                        width: 38, // Make it square
                        child: ElevatedButton(
                          onPressed: _resetToThisWeek,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9), // Match history page radius
                            ),
                            padding: EdgeInsets.zero, // Remove padding to make it square
                            minimumSize: const Size(38, 38), // Ensure proper sizing
                          ),
                          child: const Icon(Icons.refresh, size: 24), // Match history page icon size
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Team Toggle - Wrap gracefully
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final needsWrap = availableWidth < 600; // Same breakpoint as above

                return Wrap(
                  spacing: needsWrap ? 10 : 8, // 10px in compact mode, 8px in full mode
                  runSpacing: needsWrap ? 10 : 8, // 10px in compact mode, 8px in full mode
                  children: [
                    // Personal button - 120px width
                    SizedBox(
                      width: 120,
                      height: 38,
                      child: Material(
                        color: Colors.transparent,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showTeam = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showTeam
                                ? colors.primaryBlue
                                : Colors.white,
                            foregroundColor: !_showTeam ? Colors.white : colors.darkGray,
                            elevation: !_showTeam ? 2 : 0, // Add elevation for active state
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9), // Match history page radius
                            ),
                            side: BorderSide(
                              color: !_showTeam
                                  ? colors.primaryBlue
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? colors.borderColorDark
                                      : colors.borderColorLight,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.personal,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16, // Match history page font size
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Team button - 120px width
                    SizedBox(
                      width: 120,
                      height: 38,
                      child: Material(
                        color: Colors.transparent,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showTeam = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showTeam
                                ? colors.primaryBlue
                                : Colors.white,
                            foregroundColor: _showTeam ? Colors.white : colors.darkGray,
                            elevation: _showTeam ? 2 : 0, // Add elevation for active state
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9), // Match history page radius
                            ),
                            side: BorderSide(
                              color: _showTeam
                                  ? colors.primaryBlue
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? colors.borderColorDark
                                      : colors.borderColorLight,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.team,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16, // Match history page font size
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        // Add spacing between filter and table
        const SizedBox(height: 10),
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
                // Show approved and pending in calendar; rejected are hidden
                .where('status', whereIn: ['approved', 'pending']).snapshots(),
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
                        showYearView: true, // Explicitly show year view
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
          // Show approved and pending in calendar; rejected are hidden
          .where('status', whereIn: ['approved', 'pending']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.error,
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
                      AppLocalizations.of(context)!.error,
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
                          AppLocalizations.of(context)!.error,
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
                      return Center(
                          child: Text(
                              AppLocalizations.of(context)!.noMembersFound));
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
                      showYearView:
                          false, // Explicitly set to false for week/month views
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.unknownUser;
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
      final membersIterable = snapshot.docs.map((doc) {
        final data = doc.data();
        final name = data['name'] ??
            data['displayName'] ??
            data['firstName'] ??
            data['fullName'] ??
            data['userName'] ??
            l10n.unknownUser;
        return {
          'id': doc.id,
          'name': name,
          'lastName': data['surname'] ?? '',
          'email': data['email'] ?? '',
        };
      });
      return membersIterable.toList();
    }).catchError((error) {
      return <Map<String, dynamic>>[];
    });
  }
}
