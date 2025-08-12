import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';

class TimelineView extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<Map<String, dynamic>> teamMembers;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> timeOffRequests;
  final Map<String, Map<String, dynamic>> policies;
  final Map<String, Map<String, dynamic>> holidayPolicies;
  final AppColors colors;

  const TimelineView({
    Key? key,
    required this.weekStart,
    required this.weekEnd,
    required this.teamMembers,
    required this.timeOffRequests,
    required this.policies,
    required this.holidayPolicies,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate days for the date range
    final days = <DateTime>[];
    DateTime current = weekStart;
    while (current.isBefore(weekEnd) || current.isAtSameMomentAs(weekEnd)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Check if this is a year view (more than 31 days)
    if (days.length > 31) {
      return _buildYearView();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.darkGray.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIXED left sidebar - Team Member header and names (NEVER scrolls)
          Container(
            width: 120,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colors.darkGray.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Team Member header
                Container(
                  width: 120,
                  height:
                      100, // Height to cover all 3 header rows (30 + 30 + 40)
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.darkGray.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Team Member',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.darkGray,
                      ),
                    ),
                  ),
                ),
                // Team member names
                ...teamMembers.take(3).map((member) {
                  return Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colors.darkGray.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Center(
                      child: Text(
                        '${member['name'] ?? member['id'] ?? 'Unknown'} ${member['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // SCROLLABLE right side - only the dates and data scroll
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: days.length * 40.0,
                child: Column(
                  children: [
                    // Month spans row
                    Row(
                      children: _buildMonthSpans(days, colors),
                    ),
                    // Week spans row
                    Row(
                      children: _buildWeekSpans(days, colors),
                    ),
                    // Day headers row
                    Row(
                      children: days.map((day) {
                        final isWeekend = day.weekday > 5;
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isWeekend
                                ? colors.darkGray.withValues(alpha: 0.05)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: colors.darkGray.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              right: day == days.last
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: colors.darkGray
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Day abbreviation
                              Text(
                                [
                                  'Mo',
                                  'Tu',
                                  'We',
                                  'Th',
                                  'Fr',
                                  'Sa',
                                  'Su'
                                ][day.weekday - 1],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.darkGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // Date number
                              Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.darkGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    // Team member data rows
                    ...teamMembers.take(3).map((member) {
                      return Row(
                        children: days.map((day) {
                          final isWeekend = day.weekday > 5;
                          final timeOffs = _getTimeOffForDay(
                              day, member['id'], timeOffRequests);
                          final holiday =
                              _getHolidayForDay(day, holidayPolicies);

                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isWeekend
                                  ? colors.darkGray.withValues(alpha: 0.05)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: colors.darkGray.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                right: day == days.last
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: colors.darkGray
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                              ),
                            ),
                            child: _buildDayContent(
                                day, timeOffs, holiday, colors),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearView() {
    final currentYear = DateTime.now().year;
    final List<DateTime> months =
        List.generate(12, (index) => DateTime(currentYear, index + 1, 1));
    final List<String> monthNames =
        List.generate(12, (index) => DateFormat('MMMM').format(months[index]));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(12, (index) {
            final month = months[index];
            final monthName = monthNames[index];
            final monthStart = DateTime(month.year, month.month, 1);
            final monthEnd = DateTime(month.year, month.month + 1, 0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
                  child: Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.darkGray,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: TimelineView(
                    weekStart: monthStart,
                    weekEnd: monthEnd,
                    teamMembers: teamMembers,
                    timeOffRequests: timeOffRequests,
                    policies: policies,
                    holidayPolicies: holidayPolicies,
                    colors: colors,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    final weekNumber =
        ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
    return weekNumber;
  }

  List<Widget> _buildMonthSpans(List<DateTime> days, AppColors colors) {
    final monthSpans = <Widget>[];
    int currentIndex = 0;

    while (currentIndex < days.length) {
      final currentMonth = DateFormat('MMMM').format(days[currentIndex]);
      int monthEndIndex = currentIndex;

      // Find where this month ends (at month boundary)
      while (monthEndIndex < days.length &&
          days[monthEndIndex].month == days[currentIndex].month) {
        monthEndIndex++;
      }

      // Create span for this month
      final spanWidth = (monthEndIndex - currentIndex) * 40.0;
      final isLastMonth = monthEndIndex >= days.length;
      monthSpans.add(
        Container(
          width: spanWidth,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.darkGray.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  currentMonth,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.darkGray,
                  ),
                ),
              ),
              // Add right border for month splits (except last month)
              if (!isLastMonth)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: colors.darkGray.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      );

      currentIndex = monthEndIndex;
    }

    return monthSpans;
  }

  List<Widget> _buildWeekSpans(List<DateTime> days, AppColors colors) {
    final weekSpans = <Widget>[];
    int currentIndex = 0;

    while (currentIndex < days.length) {
      final currentWeekStart = days[currentIndex];
      int weekEndIndex = currentIndex;

      // Find where this week ends (at the end of weekend - Sunday)
      while (weekEndIndex < days.length) {
        final day = days[weekEndIndex];
        // If we've reached Sunday (weekday 7) or the next day is Monday (weekday 1), this week ends
        if (day.weekday == 7 ||
            (weekEndIndex + 1 < days.length &&
                days[weekEndIndex + 1].weekday == 1)) {
          weekEndIndex++;
          break;
        }
        weekEndIndex++;
      }

      // If we haven't found a Sunday, this is the last week
      if (weekEndIndex == currentIndex) {
        weekEndIndex = days.length;
      }

      // Create span for this week
      final spanWidth = (weekEndIndex - currentIndex) * 40.0;
      final weekNumber = _getWeekNumber(currentWeekStart);
      final isLastWeek = weekEndIndex >= days.length;
      weekSpans.add(
        Container(
          width: spanWidth,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.darkGray.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  'W$weekNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.darkGray,
                  ),
                ),
              ),
              // Add right border for week splits (except last week)
              if (!isLastWeek)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: colors.darkGray.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      );

      currentIndex = weekEndIndex;
    }

    return weekSpans;
  }

  List<Map<String, dynamic>> _getTimeOffForDay(
    DateTime day,
    String userId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> timeOffRequests,
  ) {
    return timeOffRequests
        .where((request) {
          final data = request.data();
          final requestUserId = data['userId'] as String?;
          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          return requestUserId == userId &&
              startDate != null &&
              endDate != null &&
              day.isAfter(startDate.subtract(const Duration(days: 1))) &&
              day.isBefore(endDate.add(const Duration(days: 1)));
        })
        .map((request) => request.data())
        .toList();
  }

  Map<String, dynamic>? _getHolidayForDay(
    DateTime day,
    Map<String, Map<String, dynamic>> holidayPolicies,
  ) {
    // Check each policy's direct date field (each policy IS a holiday)
    for (final policy in holidayPolicies.values) {
      final policyDate = policy['date'] as Timestamp?;
      if (policyDate != null) {
        final parsedDate = policyDate.toDate();
        if (parsedDate.year == day.year &&
            parsedDate.month == day.month &&
            parsedDate.day == day.day) {
          return policy; // Return the entire policy as the holiday
        }
      }
    }
    return null;
  }

  Widget _buildDayContent(
    DateTime day,
    List<Map<String, dynamic>> timeOffs,
    Map<String, dynamic>? holiday,
    AppColors colors,
  ) {
    if (holiday != null) {
      return _buildHolidayBar(holiday, colors);
    }

    if (timeOffs.isNotEmpty) {
      return _buildTimeOffBar(timeOffs.first, colors, policies);
    }

    return const SizedBox.shrink();
  }

  Widget _buildTimeOffBar(Map<String, dynamic> timeOff, AppColors colors,
      Map<String, Map<String, dynamic>> policies) {
    // Get the policy information to determine color and type
    final policyName = timeOff['policyName'] as String? ?? '';
    final policy = policies[policyName];

    Color barColor;
    String tooltipText = '';

    if (policy != null) {
      // Use the actual policy color from Firestore
      final colorHex = policy['color'] as String?;
      if (colorHex != null && colorHex.isNotEmpty) {
        try {
          barColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        } catch (e) {
          barColor = colors.primaryBlue; // Fallback color
        }
      } else {
        barColor = colors.primaryBlue; // Fallback color
      }

      final policyName = policy['name'] as String? ?? '';
      final description = timeOff['description'] ?? '';
      tooltipText =
          '$policyName\n${DateFormat('MMM dd').format(timeOff['startDate'])} - ${DateFormat('MMM dd').format(timeOff['endDate'])}';
      if (description.isNotEmpty) {
        tooltipText += '\n$description';
      }
    } else {
      // Fallback for unknown policies
      barColor = colors.primaryBlue;
      tooltipText =
          '${DateFormat('MMM dd').format(timeOff['startDate'])} - ${DateFormat('MMM dd').format(timeOff['endDate'])}\n${timeOff['description']}';
    }

    return Tooltip(
      message: tooltipText,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const SizedBox(
          width: 36,
          height: 16,
        ),
      ),
    );
  }

  Widget _buildHolidayBar(Map<String, dynamic> holiday, AppColors colors) {
    // Handle different color formats from policies
    Color barColor;

    final colorValue = holiday['color'];
    if (colorValue is int) {
      // Color is stored as integer (like 4283215696)
      barColor = Color(colorValue);
    } else if (colorValue is String) {
      // Color is stored as hex string
      try {
        barColor = Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
      } catch (e) {
        barColor = colors.error; // Red for holidays
      }
    } else {
      barColor = colors.error; // Red for holidays
    }

    // Convert Timestamp to DateTime for formatting
    final holidayDate = (holiday['date'] as Timestamp?)?.toDate();
    final formattedDate = holidayDate != null
        ? DateFormat('dd/MM/yyyy').format(holidayDate)
        : 'Unknown date';

    return Tooltip(
      message: '${holiday['name']}\n$formattedDate',
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const SizedBox(
          width: 36,
          height: 16,
        ),
      ),
    );
  }
}
