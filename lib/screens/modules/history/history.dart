import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/calendar.dart';
import '../../../services/overtime_calculation_service.dart';
import '../team/members/members_view.dart';


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
              setState(() {
                groupType = val;
                // Reset date range when switching to a different grouping type
                dateRange = null;
              });
            }
          },
        ),
      ),
    );

    // Project and Note filters
         final projectBox = Container(
       height: kFilterHeight,
       width: 150,
       decoration: pillDecoration,
       padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
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
            contentPadding: EdgeInsets.zero,
          ),
          style: pillTextStyle,
          onChanged: (v) => setState(() => searchProject = v.trim()),
        ),
      ),
    );

    final noteBox = Container(
      height: kFilterHeight,
      decoration: pillDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
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
            contentPadding: EdgeInsets.zero,
          ),
          style: pillTextStyle,
          onChanged: (v) => setState(() => searchNote = v.trim()),
        ),
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

                  // Filter logs: exclude today's sessions (they belong in tracker view)
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

                     // Exclude today's sessions from history view ONLY when viewing default unfiltered day view
                     // Show today's sessions in month/week/year views or when any filters are applied
                     if (begin != null && 
                         dateRange == null && 
                         searchProject.isEmpty && 
                         searchNote.isEmpty && 
                         groupType == GroupType.day) {
                       final today = DateTime.now();
                       final sessionDate = DateTime(begin.year, begin.month, begin.day);
                       final todayOnly = DateTime(today.year, today.month, today.day);
                       
                       // Only exclude today's sessions when viewing unfiltered day view
                       if (sessionDate.isAtSameMomentAs(todayOnly)) {
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
                      
                      // Status fields
                      bool isApproved = false;
                      bool isRejected = false;
                      bool isApprovedAfterEdit = false;
                      bool isEdited = false;

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

                        // Extract approval status
                        final approvedRaw = data['approved'];
                        final rejectedRaw = data['rejected'];
                        final approvedAfterEditRaw = data['approvedAfterEdit'];
                        final editedRaw = data['edited'];
                        
                        isApproved = approvedRaw == true ||
                            approvedRaw == 1 ||
                            approvedRaw == '1';
                        isRejected = rejectedRaw == true ||
                            rejectedRaw == 1 ||
                            rejectedRaw == '1';
                        isApprovedAfterEdit = approvedAfterEditRaw == true ||
                            approvedAfterEditRaw == 1 ||
                            approvedAfterEditRaw == '1';
                        isEdited = editedRaw == true ||
                            editedRaw == 1 ||
                            editedRaw == '1';

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
                        isApproved: isApproved,
                        isRejected: isRejected,
                        isApprovedAfterEdit: isApprovedAfterEdit,
                        isEdited: isEdited,
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
                  
                  // Check if we have a custom date range selected
                  bool hasCustomDateRange = dateRange != null && 
                      (dateRange!.startDate != null || dateRange!.endDate != null);
                  
                  for (var entry in entries) {
                    String key = '';
                    if (entry.begin == null) {
                      key = l10n.unknown;
                    } else if (hasCustomDateRange) {
                      // For custom date range, group all entries together
                      key = _formatDateRange(dateRange!, false);
                    } else {
                      // Normal grouping by selected type
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
                      // For custom date ranges, no sorting needed (only one group)
                      if (hasCustomDateRange) {
                        return 0;
                      }
                      
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
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            
                                            // Status icons and edit button - left aligned
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: [
                                                  // Status indicators
                                                  if (entry.isApprovedAfterEdit)
                                                    const Icon(Icons.verified,
                                                        color: Colors.orange, size: 20)
                                                  else if (entry.isApproved)
                                                    const Icon(Icons.verified,
                                                        color: Colors.green, size: 20)
                                                  else if (entry.isRejected)
                                                    const Icon(Icons.cancel,
                                                        color: Colors.red, size: 20)
                                                  else if (entry.isEdited)
                                                    // Edited session waiting for approval - show both icons
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.verified,
                                                            color: Colors.orange, size: 20),
                                                        const SizedBox(width: 8),
                                                        const Icon(Icons.hourglass_empty,
                                                            color: Colors.orange, size: 20),
                                                      ],
                                                    )
                                                  else
                                                    // Pending status (not approved, not rejected, not edited)
                                                    const Icon(Icons.hourglass_empty,
                                                        color: Colors.orange, size: 20),
                                                  
                                                  const SizedBox(width: 8),
                                                  
                                                  // Edit icon for rejected sessions and regular pending (not edited ones)
                                                  if (entry.isRejected || (!entry.isApproved && !entry.isRejected && !entry.isApprovedAfterEdit && !entry.isEdited))
                                                    IconButton(
                                                      onPressed: () => _showEditDialog(context, entry),
                                                      icon: Icon(Icons.edit, color: Theme.of(context).extension<AppColors>()!.primaryBlue, size: 20),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                ],
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
                              child: FutureBuilder<Map<String, dynamic>?>(
                                future: hasCustomDateRange 
                                    ? _calculateOvertimeForCustomDateRange()
                                    : _calculateGroupOvertime(groupList),
                                builder: (context, overtimeSnapshot) {
                                  List<Widget> totalWidgets = [
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
                                  ];

                                  // Add overtime if available
                                  if (overtimeSnapshot.hasData && overtimeSnapshot.data != null) {
                                    final overtimeData = overtimeSnapshot.data!;
                                    final overtimeMinutes = overtimeData['overtimeMinutes'] as int? ?? 0;
                                    final isOvertime = overtimeMinutes > 0;
                                    final color = isOvertime ? Colors.green : Colors.red;
                                    
                                    totalWidgets.add(
                                      Text(
                                        'Overtime: ${_formatOvertimeHours(overtimeMinutes / 60)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    );
                                  }

                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 4,
                                    children: totalWidgets,
                                  );
                                },
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

  // Helper method to calculate overtime for a group of entries
  Future<Map<String, dynamic>?> _calculateGroupOvertime(List<_HistoryEntry> entries) async {
    try {
      if (entries.isEmpty) return null;
      
      // Get the first entry to determine the period
      final firstEntry = entries.first;
      if (firstEntry.begin == null) return null;
      
      DateTime fromDate;
      DateTime toDate;
      
      // Calculate date range based on groupType
      switch (groupType) {
        case GroupType.month:
          // Month: 1st to last day of month (full month, not just to today)
          fromDate = DateTime(firstEntry.begin!.year, firstEntry.begin!.month, 1);
          final lastDayOfMonth = DateTime(firstEntry.begin!.year, firstEntry.begin!.month + 1, 0).day;
          toDate = DateTime(firstEntry.begin!.year, firstEntry.begin!.month, lastDayOfMonth, 23, 59, 59, 999);
          break;
        case GroupType.week:
          // Full week: Monday to Sunday using ISO week calculation (same as team members view)
          final weekParts = _getWeekInfo(firstEntry.begin!);
          final year = weekParts['year'] as int;
          final weekNumber = weekParts['weekNumber'] as int;
          final jan4 = DateTime(year, 1, 4);
          final startOfYear = jan4.subtract(Duration(days: jan4.weekday - 1));
          final weekStart = startOfYear.add(Duration(days: (weekNumber - 1) * 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          fromDate = weekStart;
          toDate = weekEnd; // Sunday is already included (weekStart + 6 days)
          break;
        case GroupType.year:
          // Full year: January 1st to December 31st
          fromDate = DateTime(firstEntry.begin!.year, 1, 1);
          toDate = DateTime(firstEntry.begin!.year, 12, 31, 23, 59, 59);
          break;
        case GroupType.day:
          // Single day
          fromDate = DateTime(firstEntry.begin!.year, firstEntry.begin!.month, firstEntry.begin!.day);
          toDate = DateTime(firstEntry.begin!.year, firstEntry.begin!.month, firstEntry.begin!.day, 23, 59, 59);
          break;
      }
      
      // Calculate overtime for the full period using the same service
      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        widget.userId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      // Use 'current' field for consistency with other views
      final overtimeMinutes = result['current'] as int? ?? 0;
      
      return {
        'overtimeMinutes': overtimeMinutes,
        'overtimeHours': (overtimeMinutes / 60).toStringAsFixed(2),
      };
    } catch (e) {
      return null;
    }
  }

  // Helper method to calculate overtime for a custom date range
  Future<Map<String, dynamic>?> _calculateOvertimeForCustomDateRange() async {
    try {
      if (dateRange == null || dateRange!.startDate == null || dateRange!.endDate == null) {
        return null;
      }

      final fromDate = dateRange!.startDate!;
      final toDate = dateRange!.endDate!;

      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        widget.userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      final overtimeMinutes = result['current'] as int? ?? 0;

      return {
        'overtimeMinutes': overtimeMinutes,
        'overtimeHours': (overtimeMinutes / 60).toStringAsFixed(2),
      };
    } catch (e) {
      return null;
    }
  }

  // Helper method to get week information (same logic as team members view)
  Map<String, dynamic> _getWeekInfo(DateTime date) {
    final weekNumber = _weekNumber(date);
    return {
      'year': date.year,
      'weekNumber': weekNumber,
    };
  }

  // Helper method to format overtime hours
  String _formatOvertimeHours(double hours) {
    final isNegative = hours < 0;
    final absHours = hours.abs();
    final h = absHours.floor();
    final m = ((absHours - h) * 60).round();
    
    String result = '';
    if (h > 0) {
      result += '${h}h';
    }
    if (m > 0 || result.isNotEmpty) {
      result += '${result.isNotEmpty ? ' ' : ''}${m.toString().padLeft(2, '0')}m';
    }
    if (result.isEmpty) {
      result = '0h 00m';
    }
    
    return isNegative ? '-$result' : result;
  }

  // Show edit dialog for history entries
  Future<void> _showEditDialog(BuildContext context, _HistoryEntry entry) async {
    // Store context reference before async operations
    final messenger = ScaffoldMessenger.of(context);
    
    // Get the log document reference
    final logDoc = await _getLogDocument(entry.sessionDate, entry.begin);
    if (logDoc == null) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not find log document to edit'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get projects list for the company
    final projects = await _getProjectsList();
    
    // Get user name for initials display
    final userName = await _getUserName();
    
    // Show simplified edit dialog for history
    if (mounted) {
      await _showHistoryEditDialog(this.context, logDoc, projects, userName);
    }
  }

  // Get log document reference
  Future<DocumentSnapshot?> _getLogDocument(String sessionDate, DateTime? begin) async {
    try {
      final companyId = widget.companyId;
      final userId = widget.userId;
      
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: sessionDate)
          .get();

      // Find the log with matching time
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final logBegin = (data['begin'] as Timestamp?)?.toDate();
        if (logBegin != null && begin != null) {
          // Compare hours and minutes
          if (logBegin.hour == begin.hour && logBegin.minute == begin.minute) {
            return doc;
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting log document: $e');
      return null;
    }
  }

  // Get projects list
  Future<List<String>> _getProjectsList() async {
    try {
      final companyId = widget.companyId;
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('projects')
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting projects list: $e');
      return [];
    }
  }

  // Get user name for initials display
  Future<String> _getUserName() async {
    try {
      final companyId = widget.companyId;
      final userId = widget.userId;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] as String? ?? 'Worker';
      }
      return 'Worker';
    } catch (e) {
      AppLogger.error('Error getting user name: $e');
      return 'Worker';
    }
  }

  // Show edit dialog for history entries using the shared edit log dialog
  Future<void> _showHistoryEditDialog(
    BuildContext context, 
    DocumentSnapshot logDoc, 
    List<String> projects, 
    String workerName
  ) async {
    // Use the shared edit log dialog from team members module
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditLogDialog(
        logDoc: logDoc,
        projects: projects,
        isWorkerMode: true, // Workers edit their own logs
        workerName: workerName, // Pass worker name for initials display
        onSaved: () {
          // Refresh the history view
          setState(() {});
        },
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
  final bool isApproved;
  final bool isRejected;
  final bool isApprovedAfterEdit;
  final bool isEdited;

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
    required this.isApproved,
    required this.isRejected,
    required this.isApprovedAfterEdit,
    required this.isEdited,
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




