import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/calendar.dart';

const double kFilterHeight = 38;
const double kFilterRadius = 9;
const double kFilterSpacing = 8;
const double kFilterFontSize = 16;

enum GroupType { day, week, month, year }

class HistoryLogs extends StatefulWidget {
  final String companyId;
  final String userId;

  const HistoryLogs({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<HistoryLogs> createState() => _HistoryLogsState();
}

class _HistoryLogsState extends State<HistoryLogs> {
  DateRange? dateRange;
  String searchNote = '';
  String searchProject = '';
  GroupType groupType = GroupType.day;

  late final TextEditingController projectController;
  late final TextEditingController noteController;

     final dateFormat = DateFormat('dd/MM/yyyy');
   final timeFormat = DateFormat('HH:mm');
   final expenseFormat = NumberFormat.currency(symbol: "CHF ", decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    projectController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    projectController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('all_logs')
        .orderBy('begin', descending: true);

    final appColors = Theme.of(context).extension<AppColors>()!;

    BoxDecoration pillDecoration = BoxDecoration(
      border: Border.all(
        color: isDark ? appColors.borderColorDark : appColors.borderColorLight,
        width: 1,
      ),
      color: isDark ? appColors.cardColorDark : appColors.backgroundLight,
      borderRadius: BorderRadius.circular(10),
    );

    TextStyle pillTextStyle = TextStyle(
      fontSize: kFilterFontSize,
      fontWeight: FontWeight.w500,
      color: isDark
          ? const Color(0xFFB3B3B3)
          : Colors.black.withValues(alpha: 0.87),
    );

    // Date range picker widget
    final dateRangeField = InkWell(
      borderRadius: BorderRadius.circular(kFilterRadius),
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: appColors.backgroundLight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              padding: const EdgeInsets.all(10),
              child: CustomCalendar(
                initialDateRange: dateRange,
                                 onDateRangeChanged: (newDateRange) {
                   setState(() {
                     // If only one date is selected, treat it as both start and end
                     if (newDateRange.startDate != null && newDateRange.endDate == null) {
                       dateRange = DateRange(
                         startDate: newDateRange.startDate,
                         endDate: newDateRange.startDate,
                       );
                     } else {
                       dateRange = newDateRange;
                     }
                   });
                 },
                minDate: DateTime(2023),
                maxDate: DateTime(2100),
                title: l10n.pickDates,
              ),
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: kFilterHeight,
          maxHeight: 60, // Always allow expansion for wrapped text
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pillDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 200;
                  return Text(
                    dateRange == null ? l10n.pickDates : _formatDateRange(dateRange!, isCompact),
                    style: TextStyle(
                      color: dateRange == null
                          ? theme.colorScheme.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.87)
                              : Colors.black.withValues(alpha: 0.87)),
                      fontWeight: FontWeight.w500,
                      fontSize: kFilterFontSize,
                    ),
                    overflow: TextOverflow.visible,
                    maxLines: 2, // Allow up to 2 lines
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Group type dropdown
    final groupDropdown = Container(
      height: kFilterHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: pillDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GroupType>(
          value: groupType,
          style: pillTextStyle,
          icon: const Icon(Icons.keyboard_arrow_down, size: 22),
          items: [
            DropdownMenuItem(
              value: GroupType.day,
              child: Text(AppLocalizations.of(context)!.day),
            ),
            DropdownMenuItem(
              value: GroupType.week,
              child: Text(AppLocalizations.of(context)!.week),
            ),
            DropdownMenuItem(
              value: GroupType.month,
              child: Text(AppLocalizations.of(context)!.month),
            ),
            DropdownMenuItem(
              value: GroupType.year,
              child: Text(AppLocalizations.of(context)!.year),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => groupType = val);
            }
          },
        ),
      ),
    );

    // Project and Note filters
         final projectBox = Container(
       height: kFilterHeight,
       width: 150,
       alignment: Alignment.centerLeft,
       decoration: pillDecoration,
       padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: projectController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.project,
          hintStyle: TextStyle(
            color: isDark
                ? const Color(0xFFB3B3B3)
                : Colors.black.withValues(alpha: 0.87),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
        style: pillTextStyle,
        onChanged: (v) => setState(() => searchProject = v.trim()),
      ),
    );

    final noteBox = Container(
      height: kFilterHeight,
      alignment: Alignment.centerLeft,
      decoration: pillDecoration,
             padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: noteController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.note,
          hintStyle: TextStyle(
            color: isDark
                ? const Color(0xFFB3B3B3)
                : Colors.black.withValues(alpha: 0.87),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
        style: pillTextStyle,
        onChanged: (v) => setState(() => searchNote = v.trim()),
      ),
    );

    // Refresh button
    final refreshBtn = SizedBox(
      height: kFilterHeight,
      width: kFilterHeight, // Make it square
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            dateRange = null;
            searchProject = '';
            searchNote = '';
            groupType = GroupType.day;
          });
          projectController.clear();
          noteController.clear();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero, // Remove padding to make it square
        ),
        child: const Icon(Icons.refresh, size: 24),
      ),
    );

    return Scaffold(
      backgroundColor: appColors.dashboardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            // Search filters
                    Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? appColors.cardColorDark
                : appColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? appColors.borderColorDark : appColors.borderColorLight,
              width: 1,
            ),
          ),
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final needsWrap = constraints.maxWidth < 800;

                  if (needsWrap) {
                    return Wrap(
                      spacing: kFilterSpacing,
                      runSpacing: 8,
                      children: [
                        // Individual elements that will wrap in order
                        dateRangeField,
                        groupDropdown,
                        refreshBtn,
                        projectBox,
                        noteBox,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        dateRangeField,
                        const SizedBox(width: kFilterSpacing),
                        groupDropdown,
                        const SizedBox(width: kFilterSpacing),
                        refreshBtn,
                        const SizedBox(width: kFilterSpacing),
                        projectBox,
                        const SizedBox(width: kFilterSpacing),
                        Expanded(child: noteBox),
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // Results
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: logsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noLogsFound,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF969696)
                              : const Color(0xFF6A6A6A),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  var logs = snapshot.data!.docs;

                  List<QueryDocumentSnapshot> filteredLogs = logs.where((doc) {
                                         final data = doc.data() as Map<String, dynamic>;
                     final begin = (data['begin'] is Timestamp)
                         ? (data['begin'] as Timestamp).toDate()
                         : null;
                     final end = (data['end'] is Timestamp)
                         ? (data['end'] as Timestamp).toDate()
                         : null;
                     final project = (data['project'] ?? '').toString();
                     final note = (data['note'] ?? '').toString();

                                         if (dateRange?.startDate != null && dateRange?.endDate != null && begin != null) {
                       final rangeStart = dateRange!.startDate!;
                       final rangeEnd = dateRange!.endDate!;
                       
                       // Check if the session overlaps with the selected date range
                       // A session overlaps if:
                       // 1. Session starts within the range, OR
                       // 2. Session ends within the range, OR  
                       // 3. Session completely contains the range
                       
                       bool sessionOverlaps = false;
                       
                       if (end != null) {
                         // Session has both start and end times
                         // Check if session overlaps with the date range
                         final sessionStart = begin;
                         final sessionEnd = end;
                         
                         // Convert to date-only comparison (ignore time)
                         final sessionStartDate = DateTime(sessionStart.year, sessionStart.month, sessionStart.day);
                         final sessionEndDate = DateTime(sessionEnd.year, sessionEnd.month, sessionEnd.day);
                         final rangeStartDate = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
                         final rangeEndDate = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
                         
                         // Check for overlap
                         sessionOverlaps = !(sessionEndDate.isBefore(rangeStartDate) || sessionStartDate.isAfter(rangeEndDate));
                       } else {
                         // Session only has start time, check if start date is within range
                         final sessionDate = DateTime(begin.year, begin.month, begin.day);
                         final rangeStartDate = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
                         final rangeEndDate = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
                         
                         sessionOverlaps = !(sessionDate.isBefore(rangeStartDate) || sessionDate.isAfter(rangeEndDate));
                       }
                       
                       if (!sessionOverlaps) {
                         return false;
                       }
                     } else if (dateRange?.startDate != null && dateRange?.endDate == null && begin != null) {
                       // Single date selected - check if session is on that date
                       final selectedDate = dateRange!.startDate!;
                       final sessionDate = DateTime(begin.year, begin.month, begin.day);
                       final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                       
                       if (!sessionDate.isAtSameMomentAs(selectedDateOnly)) {
                         return false;
                       }
                     }

                    if (searchProject.isNotEmpty &&
                        !project
                            .toLowerCase()
                            .contains(searchProject.toLowerCase())) {
                      return false;
                    }

                    if (searchNote.isNotEmpty &&
                        !note
                            .toLowerCase()
                            .contains(searchNote.toLowerCase())) {
                      return false;
                    }

                    return true;
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return Center(child: Text(l10n.noEntriesMatchFilters));
                  }

                  // Process all logs into entries
                  List<_HistoryEntry> entries = [];
                  for (var doc in filteredLogs) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;

                      // Safe data extraction
                      DateTime? begin;
                      DateTime? end;
                      String project = '';
                      String note = '';
                      String sessionDate = '';
                      bool perDiem = false;
                      Duration duration = Duration.zero;
                      double totalExpense = 0.0;
                      Map<String, dynamic> expensesMap = {};

                      try {
                        begin = (data['begin'] is Timestamp)
                            ? (data['begin'] as Timestamp).toDate()
                            : null;
                        end = (data['end'] is Timestamp)
                            ? (data['end'] as Timestamp).toDate()
                            : null;
                        project = (data['project'] ?? '').toString();
                        note = (data['note'] ?? '').toString();
                        sessionDate = (data['sessionDate'] ?? '').toString();

                        final perDiemRaw = data['perDiem'];
                        perDiem = perDiemRaw == true ||
                            perDiemRaw == 1 ||
                            perDiemRaw == '1';

                        // Calculate duration
                        if (begin != null && end != null) {
                          duration = end.difference(begin);
                        }

                        // Process expenses safely
                        final rawExpenses = data['expenses'];
                        if (rawExpenses is Map) {
                          expensesMap = Map<String, dynamic>.from(rawExpenses);

                          for (var entry in expensesMap.entries) {
                            try {
                              final v = entry.value;
                              if (v is num) {
                                totalExpense += v.toDouble();
                              } else if (v is String) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) totalExpense += parsed;
                              } else if (v is bool) {
                                // Skip boolean values
                                continue;
                              }
                            } catch (e) {
                              AppLogger.error(
                                  'Error processing expense entry ${entry.key}: $e');
                              continue;
                            }
                          }
                        }
                      } catch (e) {
                        AppLogger.error('Error processing log data: $e');
                      }

                      entries.add(_HistoryEntry(
                        begin: begin,
                        end: end,
                        duration: duration,
                        project: project,
                        note: note,
                        sessionDate: sessionDate,
                        perDiem: perDiem,
                        expense: totalExpense,
                        expensesMap: expensesMap,
                      ));
                    } catch (e) {
                      AppLogger.error('Error creating history entry: $e');
                      continue;
                    }
                  }

                  // Sort by begin date descending
                  entries.sort((a, b) {
                    if (a.begin == null) {
                      return 1;
                    }
                    if (b.begin == null) {
                      return -1;
                    }
                    return b.begin!.compareTo(a.begin!);
                  });

                  // Group entries
                  Map<String, List<_HistoryEntry>> grouped = {};
                  for (var entry in entries) {
                    String key = '';
                    if (entry.begin == null) {
                      key = l10n.unknown;
                    } else {
                      switch (groupType) {
                        case GroupType.day:
                          key = dateFormat.format(entry.begin!);
                          break;
                        case GroupType.week:
                          final week = _weekNumber(entry.begin!);
                          key = '${l10n.week} $week, ${entry.begin!.year}';
                          break;
                        case GroupType.month:
                          key = DateFormat('MMMM yyyy').format(entry.begin!);
                          break;
                        case GroupType.year:
                          key = '${entry.begin!.year}';
                          break;
                      }
                    }
                    grouped.putIfAbsent(key, () => []).add(entry);
                  }

                  // Sort group keys
                  final sortedKeys = grouped.keys.toList()
                    ..sort((a, b) {
                      if (groupType == GroupType.day) {
                        try {
                          return DateTime.parse(b).compareTo(DateTime.parse(a));
                        } catch (_) {}
                      } else if (groupType == GroupType.year) {
                        return int.parse(b).compareTo(int.parse(a));
                      } else if (groupType == GroupType.month) {
                        try {
                          final fa = DateFormat('MMMM yyyy').parse(a);
                          final fb = DateFormat('MMMM yyyy').parse(b);
                          return fb.compareTo(fa);
                        } catch (_) {}
                      } else if (groupType == GroupType.week) {
                        final wa =
                            int.tryParse(a.split(' ')[1].replaceAll(',', '')) ??
                                0;
                        final wb =
                            int.tryParse(b.split(' ')[1].replaceAll(',', '')) ??
                                0;
                        final ya = int.tryParse(a.split(',').last.trim()) ?? 0;
                        final yb = int.tryParse(b.split(',').last.trim()) ?? 0;
                        return yb != ya ? yb.compareTo(ya) : wb.compareTo(wa);
                      }
                      return a.compareTo(b);
                    });

                  // Grouped list view
                  return ListView.builder(
                    key: ValueKey(
                        'history_list_${widget.companyId}_${widget.userId}'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    cacheExtent: 1000,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, groupIdx) {
                      final groupKey = sortedKeys[groupIdx];
                      final groupList = grouped[groupKey]!;

                      // Calculate group totals
                      Duration groupTotal = Duration.zero;
                      double groupExpense = 0.0;

                      for (var e in groupList) {
                        try {
                          groupTotal += e.duration;
                          if (e.expense.isFinite && !e.expense.isNaN) {
                            groupExpense += e.expense;
                          }
                        } catch (error) {
                          AppLogger.error('Error in group calculation: $error');
                        }
                      }

                              return Container(
          key: ValueKey('history_group_$groupKey'),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? appColors.cardColorDark
                : appColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? appColors.borderColorDark : appColors.borderColorLight,
              width: 1,
            ),
          ),
                        child: Column(
                          children: [
                            // Group header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.1)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                groupKey,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            // Group entries
                            ...groupList
                                .map((entry) => Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          (entry.begin != null &&
                                                  entry.end != null)
                                              ? '${dateFormat.format(entry.begin!)}  ${timeFormat.format(entry.begin!)} - ${timeFormat.format(entry.end!)}'
                                              : entry.sessionDate,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFFCCCCCC)
                                                : const Color(0xFF212121),
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (entry.project.isNotEmpty)
                                              Text(
                                                '${l10n.project}: ${entry.project}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? const Color(0xFF969696)
                                                      : const Color(0xFF6A6A6A),
                                                ),
                                              ),
                                            if (entry.duration != Duration.zero)
                                              Text(
                                                '${l10n.duration}: ${_formatDuration(entry.duration)}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? const Color(0xFF969696)
                                                      : const Color(0xFF6A6A6A),
                                                ),
                                              ),
                                            if (entry.note.isNotEmpty)
                                              Text(
                                                '${l10n.note}: ${entry.note}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? const Color(0xFF969696)
                                                      : const Color(0xFF6A6A6A),
                                                ),
                                              ),
                                            if (entry.perDiem)
                                              Text(
                                                '${l10n.perDiem}: ${l10n.yes}',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            if (entry.expensesMap.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ...entry.expensesMap.entries
                                                        .map((e) {
                                                      if (e.value is bool) {
                                                        return Text(
                                                          '${_translateExpenseKey(e.key, l10n)}: ${e.value ? l10n.yes : l10n.no}',
                                                          style: TextStyle(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              fontSize: 15),
                                                        );
                                                      } else {
                                                        double expenseValue = 0.0;
                                                        if (e.value is num) {
                                                          expenseValue =
                                                              (e.value as num)
                                                                  .toDouble();
                                                        } else if (e.value
                                                            is String) {
                                                          expenseValue =
                                                              double.tryParse(e
                                                                          .value
                                                                      as String) ??
                                                                  0.0;
                                                        }
                                                        return Text(
                                                          '${_translateExpenseKey(e.key, l10n)}: ${expenseFormat.format(expenseValue)}',
                                                          style: TextStyle(
                                                              color: theme
                                                                  .colorScheme
                                                                  .error,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              fontSize: 15),
                                                        );
                                                      }
                                                    }),
                                                    if (entry.expense > 0)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                top: 4.0),
                                                        child: Text(
                                                          '${l10n.totalExpenses}: ${expenseFormat.format(entry.expense)}',
                                                          style: const TextStyle(
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )
                                            else if (entry.expense > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.0),
                                                child: Text(
                                                  '${l10n.totalExpenses}: ${expenseFormat.format(entry.expense)}',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    )),
                            // Group totals footer
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.1)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.05),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '${l10n.totalTime}: ${_formatDuration(groupTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${l10n.totalExpenses}: ${expenseFormat.format(groupExpense)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
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
        ),
      ),
    );
  }
}

// Helper class for history entry
class _HistoryEntry {
  final DateTime? begin;
  final DateTime? end;
  final Duration duration;
  final String project;
  final String note;
  final String sessionDate;
  final bool perDiem;
  final double expense;
  final Map<String, dynamic> expensesMap;

  _HistoryEntry({
    required this.begin,
    required this.end,
    required this.duration,
    required this.project,
    required this.note,
    required this.sessionDate,
    required this.perDiem,
    required this.expense,
    required this.expensesMap,
  });
}

// Helper for formatting Duration as HH:MMh
String _formatDuration(Duration d) {
  if (d == Duration.zero) {
    return '';
  }
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
  return '${m}m';
}

// Calculate ISO 8601 week number
int _weekNumber(DateTime date) {
  // ISO 8601: Week 1 is the week containing January 4th
  final jan4 = DateTime(date.year, 1, 4);
  final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
  final jan4StartOfWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
  final weekNumber =
      ((startOfWeek.difference(jan4StartOfWeek).inDays) / 7).floor() + 1;
  return weekNumber;
}

 // Helper function to translate expense keys
 String _translateExpenseKey(String key, AppLocalizations l10n) {
   switch (key.toLowerCase()) {
     case 'per diem':
     case 'perdiem':
       return l10n.perDiem;
     default:
       return key;
   }
 }

 // Helper function to format date range with dd.mm.yyyy format
 String _formatDateRange(DateRange dateRange, bool isCompact) {
   if (dateRange.startDate == null && dateRange.endDate == null) {
     return 'No dates selected';
   }
   if (dateRange.startDate == null) {
     return 'End: ${DateFormat('dd.MM.yyyy').format(dateRange.endDate!)}';
   }
   if (dateRange.endDate == null) {
     return 'Start: ${DateFormat('dd.MM.yyyy').format(dateRange.startDate!)}';
   }
   if (dateRange.isSingleDate) {
     return DateFormat('dd.MM.yyyy').format(dateRange.startDate!);
   }
   
   // Only wrap on compact screens
   if (isCompact) {
     return '${DateFormat('dd/MM/yyyy').format(dateRange.startDate!)}\n${DateFormat('dd/MM/yyyy').format(dateRange.endDate!)}';
   } else {
     return '${DateFormat('dd/MM/yyyy').format(dateRange.startDate!)} - ${DateFormat('dd/MM/yyyy').format(dateRange.endDate!)}';
   }
 }
