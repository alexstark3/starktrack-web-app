import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

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

  late final TextEditingController projectController;
  late final TextEditingController noteController;

  final dateFormat = DateFormat('yyyy-MM-dd');
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
          color: Colors.black.withValues(alpha:0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    TextStyle pillTextStyle = TextStyle(
      fontSize: kFilterFontSize,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white.withValues(alpha:0.87) : Colors.black.withValues(alpha:0.87),
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
                    color: fromDate == null ? theme.colorScheme.primary : (isDark ? Colors.white.withValues(alpha:0.87) : Colors.black.withValues(alpha:0.87)),
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
                    color: toDate == null ? theme.colorScheme.primary : (isDark ? Colors.white.withValues(alpha:0.87) : Colors.black.withValues(alpha:0.87)),
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
            if (val != null) setState(() => groupType = val);
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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        controller: projectController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.project,
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
        controller: noteController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.note,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: pillTextStyle,
        onChanged: (v) => setState(() => searchNote = v.trim()),
      ),
    );

    // Refresh button
    final refreshBtn = Container(
      height: kFilterHeight,
      decoration: BoxDecoration(
        color: isDark 
          ? theme.colorScheme.primary.withValues(alpha:0.2)
          : theme.colorScheme.primary.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
            groupType = GroupType.day;
          });
          projectController.clear();
          noteController.clear();
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Search filters
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? appColors.cardColorDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final needsWrap = constraints.maxWidth < 800;
                
                if (needsWrap) {
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
          const SizedBox(height: 20),
          
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

                var logs = snapshot.data!.docs;

                List<QueryDocumentSnapshot> filteredLogs = logs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final begin = (data['begin'] is Timestamp)
                      ? (data['begin'] as Timestamp).toDate()
                      : null;
                  final project = (data['project'] ?? '').toString();
                  final note = (data['note'] ?? '').toString();

                  if (fromDate != null && begin != null && begin.isBefore(fromDate!)) return false;
                  if (toDate != null && begin != null && begin.isAfter(toDate!)) return false;

                  if (searchProject.isNotEmpty &&
                      !project.toLowerCase().contains(searchProject.toLowerCase())) {
                    return false;
                  }

                  if (searchNote.isNotEmpty &&
                      !note.toLowerCase().contains(searchNote.toLowerCase())) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No entries match your filters.'));
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
                      begin = (data['begin'] is Timestamp) ? (data['begin'] as Timestamp).toDate() : null;
                      end = (data['end'] is Timestamp) ? (data['end'] as Timestamp).toDate() : null;
                      project = (data['project'] ?? '').toString();
                      note = (data['note'] ?? '').toString();
                      sessionDate = (data['sessionDate'] ?? '').toString();
                      
                      final perDiemRaw = data['perDiem'];
                      perDiem = perDiemRaw == true || perDiemRaw == 1 || perDiemRaw == '1';
                      
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
                            print('Error processing expense entry ${entry.key}: $e');
                            continue;
                          }
                        }
                      }
                    } catch (e) {
                      print('Error processing log data: $e');
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
                    print('Error creating history entry: $e');
                    continue;
                  }
                }

                // Sort by begin date descending
                entries.sort((a, b) {
                  if (a.begin == null) return 1;
                  if (b.begin == null) return -1;
                  return b.begin!.compareTo(a.begin!);
                });

                // Group entries
                Map<String, List<_HistoryEntry>> grouped = {};
                for (var entry in entries) {
                  String key = '';
                  if (entry.begin == null) {
                    key = 'Unknown';
                  } else {
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

                // Sort group keys
                final sortedKeys = grouped.keys.toList()..sort((a, b) {
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

                // Grouped list view
                return ListView.builder(
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
                        print('Error in group calculation: $error');
                      }
                    }
                    
                                                              return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       decoration: BoxDecoration(
                         color: isDark ? appColors.cardColorDark : Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         boxShadow: isDark ? null : [
                           BoxShadow(
                             color: Colors.black.withValues(alpha:0.08),
                             blurRadius: 6,
                             offset: const Offset(0, 2),
                           ),
                         ],
                       ),
                       child: Column(
                         children: [
                           // Group header
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                             decoration: BoxDecoration(
                               color: isDark 
                                 ? theme.colorScheme.primary.withValues(alpha:0.1)
                                 : theme.colorScheme.primary.withValues(alpha:0.05),
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
                           ...groupList.map((entry) => ListTile(
                             title: Text(
                               (entry.begin != null && entry.end != null)
                                   ? '${dateFormat.format(entry.begin!)}  ${timeFormat.format(entry.begin!)} - ${timeFormat.format(entry.end!)}'
                                   : entry.sessionDate,
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 color: isDark ? const Color(0xFFCCCCCC) : Colors.black87,
                               ),
                             ),
                             subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 if (entry.project.isNotEmpty) 
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
                                 if (entry.note.isNotEmpty) 
                                   Text(
                                     'Note: ${entry.note}',
                                     style: TextStyle(
                                       color: isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A),
                                     ),
                                   ),
                                 if (entry.perDiem)
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
                                       children: [
                                         ...entry.expensesMap.entries.map((e) {
                                           if (e.value is bool) {
                                             return Text('${e.key}: ${e.value ? "Yes" : "No"}',
                                               style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 15),
                                             );
                                           } else {
                                             double expenseValue = 0.0;
                                             if (e.value is num) {
                                               expenseValue = (e.value as num).toDouble();
                                             } else if (e.value is String) {
                                               expenseValue = double.tryParse(e.value as String) ?? 0.0;
                                             }
                                             return Text('${e.key}: ${expenseFormat.format(expenseValue)}',
                                               style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 15),
                                             );
                                           }
                                         }).toList(),
                                         if (entry.expense > 0)
                                           Padding(
                                             padding: const EdgeInsets.only(top: 4.0),
                                             child: Text(
                                               'Total Expenses: ${expenseFormat.format(entry.expense)}',
                                               style: const TextStyle(
                                                 color: Colors.red,
                                                 fontWeight: FontWeight.w600,
                                                 fontSize: 15,
                                               ),
                                             ),
                                           ),
                                       ],
                                     ),
                                   )
                                 else if (entry.expense > 0)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 2.0),
                                     child: Text(
                                       'Total Expenses: ${expenseFormat.format(entry.expense)}',
                                       style: const TextStyle(
                                         color: Colors.red,
                                         fontWeight: FontWeight.w600,
                                         fontSize: 15,
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           )).toList(),
                           // Group totals footer
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                             decoration: BoxDecoration(
                               color: isDark 
                                 ? theme.colorScheme.primary.withValues(alpha:0.1)
                                 : theme.colorScheme.primary.withValues(alpha:0.05),
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
  if (d == Duration.zero) return '';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${m}m';
}

// Calculate ISO 8601 week number
int _weekNumber(DateTime date) {
  // ISO 8601: Week 1 is the week containing January 4th
  final jan4 = DateTime(date.year, 1, 4);
  final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
  final jan4StartOfWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
  final weekNumber = ((startOfWeek.difference(jan4StartOfWeek).inDays) / 7).floor() + 1;
  return weekNumber;
}
