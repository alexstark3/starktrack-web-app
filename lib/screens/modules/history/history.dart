import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

    BoxDecoration pillDecoration = BoxDecoration(
      border: Border.all(
        color: isDark ? Colors.white24 : Colors.black26, 
        width: 1
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
          ? [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
            ]
          : [
              const Color(0xFFFFFFFF),
              const Color(0xFFF8F8F8),
            ],
      ),
      borderRadius: BorderRadius.circular(kFilterRadius),
    );

    TextStyle pillTextStyle = TextStyle(
      fontSize: kFilterFontSize,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white87 : Colors.black87,
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
                    color: fromDate == null ? theme.colorScheme.primary : (isDark ? Colors.white87 : Colors.black87),
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
                    color: toDate == null ? theme.colorScheme.primary : (isDark ? Colors.white87 : Colors.black87),
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
      width: 150,
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
      width: 150,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                theme.colorScheme.primary.withOpacity(0.3),
                theme.colorScheme.primary.withOpacity(0.1),
              ]
            : [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
        ),
        borderRadius: BorderRadius.circular(kFilterRadius),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // FILTER & GROUP BAR


          Container(
  width: double.infinity, // stretch to full width!
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark 
        ? [
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xFFF8F8F8),
          ],
    ),
    border: Border.all(
      color: isDark ? Colors.white12 : Colors.grey.shade300, 
      width: 1
    ),
    borderRadius: BorderRadius.circular(kFilterRadius + 2),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  alignment: Alignment.centerLeft, // keep fields left-aligned
  child: Wrap(
    alignment: WrapAlignment.start, // aligns all children left!
    spacing: kFilterSpacing,
    runSpacing: kFilterSpacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dateGroup,
          const SizedBox(width: kFilterSpacing),
          groupDropdown,
        ],
      ),
      projectBox,
      noteBox,
      refreshBtn,
    ],
  ),
),



          
          // DATA LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: logsRef.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No entries found.'));
                }

                // Get logs and filter on client
                var logs = snap.data!.docs;

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
                  final perDiem = data['perDiem'] ?? false;
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
                      elevation: 2,
                      child: Column(
                        children: [
                          ExpansionTile(
                            initiallyExpanded: groupIdx == 0,
                            title: Text(
                              groupKey,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: groupList.map((entry) {
                              return ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (entry.begin != null && entry.end != null)
                                            ? '${dateFormat.format(entry.begin!)}  ${timeFormat.format(entry.begin!)} - ${timeFormat.format(entry.end!)}'
                                            : entry.sessionDate,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                    if (entry.project != '') Text('Project: ${entry.project}'),
                                    if (entry.duration != Duration.zero)
                                      Text('Duration: ${_formatDuration(entry.duration)}'),
                                    if (entry.note != '') Text('Note: ${entry.note}'),
                                    if (entry.perDiem == true)
                                      Text('Per diem: Yes', style: TextStyle(color: theme.colorScheme.primary)),
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
                            color: isDark ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
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
