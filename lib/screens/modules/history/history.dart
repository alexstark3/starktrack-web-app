import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

const double kFilterHeight = 38;
const double kFilterRadius = 9;
const double kFilterSpacing = 8;
const double kFilterFontSize = 16;

enum GroupType { day, week, month, year }

class HistoryLogs extends StatefulWidget {
  final String companyId;
  final String userId;

  const HistoryLogs({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<HistoryLogs> createState() => _HistoryLogsState();
}

class _HistoryLogsState extends State<HistoryLogs> {
  DateTime? fromDate;
  DateTime? toDate;
  String searchNote = '';
  String searchProject = '';
  GroupType groupType = GroupType.day;

  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm');
  final expenseFormat = NumberFormat.currency(symbol: "CHF ", decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
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
        color: isDark ? Colors.white24 : Colors.black26, 
        width: 1
      ),
      color: isDark 
        ? appColors.cardColorDark
        : Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: isDark ? null : [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    TextStyle pillTextStyle = TextStyle(
      fontSize: kFilterFontSize,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white.withOpacity(0.87) : Colors.black.withOpacity(0.87),
    );

    // From and To date pickers
    final dateGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(kFilterRadius),
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: fromDate ?? DateTime.now(),
              firstDate: DateTime(2023),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => fromDate = picked);
          },
          child: Container(
            height: kFilterHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: pillDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  fromDate == null ? "From" : dateFormat.format(fromDate!),
                  style: TextStyle(
                    color: fromDate == null ? theme.colorScheme.primary : (isDark ? Colors.white.withOpacity(0.87) : Colors.black.withOpacity(0.87)),
                    fontWeight: FontWeight.w500,
                    fontSize: kFilterFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: kFilterSpacing),
        InkWell(
          borderRadius: BorderRadius.circular(kFilterRadius),
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: toDate ?? DateTime.now(),
              firstDate: DateTime(2023),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => toDate = picked);
          },
          child: Container(
            height: kFilterHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: pillDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  toDate == null ? "To" : dateFormat.format(toDate!),
                  style: TextStyle(
                    color: toDate == null ? theme.colorScheme.primary : (isDark ? Colors.white.withOpacity(0.87) : Colors.black.withOpacity(0.87)),
                    fontWeight: FontWeight.w500,
                    fontSize: kFilterFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          items: const [
            DropdownMenuItem(
              value: GroupType.day,
              child: Text('Day'),
            ),
            DropdownMenuItem(
              value: GroupType.week,
              child: Text('Week'),
            ),
            DropdownMenuItem(
              value: GroupType.month,
              child: Text('Month'),
            ),
            DropdownMenuItem(
              value: GroupType.year,
              child: Text('Year'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => groupType = val);
          },
        ),
      ),
    );

    // Project and Note filters, same style
    final projectBox = Container(
      height: kFilterHeight,
      width: 150, // Original width for desktop
      alignment: Alignment.centerLeft,
      decoration: pillDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Project',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: pillTextStyle,
        onChanged: (v) => setState(() => searchProject = v.trim()),
      ),
    );

    final noteBox = Container(
      height: kFilterHeight,
      width: 150, // Original width for desktop
      alignment: Alignment.centerLeft,
      decoration: pillDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Note',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: pillTextStyle,
        onChanged: (v) => setState(() => searchNote = v.trim()),
      ),
    );

    // Refresh icon styled to match, but filled
    final refreshBtn = Container(
      height: kFilterHeight,
      decoration: BoxDecoration(
        color: isDark 
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.refresh, color: theme.colorScheme.primary, size: 24),
        tooltip: 'Clear filters',
        onPressed: () {
          setState(() {
            fromDate = null;
            toDate = null;
            searchProject = '';
            searchNote = '';
          });
        },
      ),
    );

    return Container(
      color: appColors.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
        children: [
          // Search filters
          Container(
            width: double.infinity, // Make it stretch full width like the list
            decoration: BoxDecoration(
              color: isDark ? appColors.cardColorDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if we need to wrap (when screen is too narrow)
                final needsWrap = constraints.maxWidth < 800;
                
                if (needsWrap) {
                  // Wrap layout for small screens
                  return Wrap(
                    spacing: kFilterSpacing,
                    runSpacing: 8,
                    children: [
                      dateGroup,
                      groupDropdown,
                      refreshBtn,
                      projectBox,
                      noteBox,
                    ],
                  );
                } else {
                  // Original single row layout for larger screens
                  return Row(
                    children: [
                      dateGroup,
                      const SizedBox(width: kFilterSpacing),
                      groupDropdown,
                      const SizedBox(width: kFilterSpacing),
                      refreshBtn,
                      const SizedBox(width: kFilterSpacing),
                      projectBox,
                      const SizedBox(width: kFilterSpacing),
                      noteBox,
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20), // Add spacing between search card and list
          
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
                      'No logs found.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                // Get logs and filter on client
                var logs = snapshot.data!.docs;

                List<QueryDocumentSnapshot> filteredLogs = logs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final begin = (data['begin'] is Timestamp)
                      ? (data['begin'] as Timestamp).toDate()
                      : null;
                  final project = (data['project'] ?? '').toString();
                  final note = (data['note'] ?? '').toString();

                  // Date range filter
                  if (fromDate != null && begin != null && begin.isBefore(fromDate!)) return false;
                  if (toDate != null && begin != null && begin.isAfter(toDate!)) return false;

                  // Project filter
                  if (searchProject.isNotEmpty &&
                      !project.toLowerCase().contains(searchProject.toLowerCase())) {
                    return false;
                  }

                  // Note filter
                  if (searchNote.isNotEmpty &&
                      !note.toLowerCase().contains(searchNote.toLowerCase())) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No entries match your filters.'));
                }

                // ==== GROUPING LOGIC STARTS HERE ====
                // Convert to models for easier handling
                List<_HistoryEntry> entries = filteredLogs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final begin = (data['begin'] is Timestamp)
                      ? (data['begin'] as Timestamp).toDate()
                      : null;
                  final end = (data['end'] is Timestamp)
                      ? (data['end'] as Timestamp).toDate()
                      : null;
                  final duration = (begin != null && end != null)
                      ? end.difference(begin)
                      : Duration.zero;
                  final project = data['project'] ?? '';
                  final note = data['note'] ?? '';
                  final sessionDate = data['sessionDate'] ?? '';
                  final perDiemRaw = data['perDiem'];
                  final perDiem = perDiemRaw == true || perDiemRaw == 1;
                  final expensesMap = Map<String, dynamic>.from(data['expenses'] ?? {});
                  double totalExpense = 0.0;
                  for (var v in expensesMap.values) {
                    if (v is num) totalExpense += v.toDouble();
                  }

                  return _HistoryEntry(
                    begin: begin,
                    end: end,
                    duration: duration,
                    project: project,
                    note: note,
                    sessionDate: sessionDate,
                    perDiem: perDiem,
                    expense: totalExpense,
                    expensesMap: expensesMap,
                  );
                }).toList();

                // Sort by begin date descending
                entries.sort((a, b) {
                  if (a.begin == null) return 1;
                  if (b.begin == null) return -1;
                  return b.begin!.compareTo(a.begin!);
                });

                // Grouping map
                Map<String, List<_HistoryEntry>> grouped = {};

                for (var entry in entries) {
                  String key = '';
                  if (entry.begin == null) key = 'Unknown';
                  else {
                    switch (groupType) {
                      case GroupType.day:
                        key = dateFormat.format(entry.begin!);
                        break;
                      case GroupType.week:
                        final week = _weekNumber(entry.begin!);
                        key = 'Week $week, ${entry.begin!.year}';
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

                // Sorted group keys (desc by date)
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
                      final wa = int.tryParse(a.split(' ')[1].replaceAll(',', '')) ?? 0;
                      final wb = int.tryParse(b.split(' ')[1].replaceAll(',', '')) ?? 0;
                      final ya = int.tryParse(a.split(',').last.trim()) ?? 0;
                      final yb = int.tryParse(b.split(',').last.trim()) ?? 0;
                      return yb != ya ? yb.compareTo(ya) : wb.compareTo(wa);
                    }
                    return a.compareTo(b);
                  });

                // ==== UI GROUPS ====
                return ListView.separated(
                  itemCount: sortedKeys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, groupIdx) {
                    final groupKey = sortedKeys[groupIdx];
                    final groupList = grouped[groupKey]!;

                    final groupTotal = groupList.fold<Duration>(
                        Duration.zero, (sum, e) => sum + e.duration);
                    final groupExpense = groupList.fold<double>(
                        0.0, (sum, e) => sum + e.expense);

                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: isDark ? 0 : 4,
                      color: isDark ? appColors.cardColorDark : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? appColors.cardColorDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ExpansionTile(
                              initiallyExpanded: groupIdx == 0,
                              title: Text(
                                groupKey,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFCCCCCC) : Colors.black87,
                                ),
                              ),
                              children: groupList.map((entry) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.access_time,
                                    color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (entry.begin != null && entry.end != null)
                                              ? '${dateFormat.format(entry.begin!)}  ${timeFormat.format(entry.begin!)} - ${timeFormat.format(entry.end!)}'
                                              : entry.sessionDate,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFCCCCCC) : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (entry.expense > 0)
                                        Text(
                                          expenseFormat.format(entry.expense),
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (entry.project != '') 
                                        Text(
                                          'Project: ${entry.project}',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                                          ),
                                        ),
                                      if (entry.duration != Duration.zero)
                                        Text(
                                          'Duration: ${_formatDuration(entry.duration)}',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                                          ),
                                        ),
                                      if (entry.note != '') 
                                        Text(
                                          'Note: ${entry.note}',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                                          ),
                                        ),
                                      if (entry.perDiem == true)
                                        Text(
                                          'Per diem: Yes', 
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      if (entry.expensesMap.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: entry.expensesMap.entries.map((e) =>
                                              Text('${e.key}: ${expenseFormat.format((e.value as num).toDouble())}',
                                                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 15),
                                              )).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            // Blue bar with group totals
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark 
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Time: ${_formatDuration(groupTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Total Expenses: ${expenseFormat.format(groupExpense)}',
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
  final double expense; // total
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
  if (d == Duration.zero) return '';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${m}m';
}

// Calculate ISO 8601 week number
int _weekNumber(DateTime date) {
  final thursday = date.add(Duration(days: (4 - date.weekday) % 7));
  final firstThursday = DateTime(thursday.year, 1, 1).add(
      Duration(days: (4 - DateTime(thursday.year, 1, 1).weekday) % 7));
  return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
}
