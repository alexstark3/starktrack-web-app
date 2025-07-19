import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import 'add_new_session.dart';

const double kFilterHeight = 38;
const double kFilterRadius = 9;
const double kFilterSpacing = 8;
const double kFilterFontSize = 16;

enum GroupType { day, week, month, year }

class MemberHistoryScreen extends StatefulWidget {
  final String companyId;
  final DocumentSnapshot memberDoc;
  final VoidCallback? onBack;

  const MemberHistoryScreen({
    Key? key,
    required this.companyId,
    required this.memberDoc,
    this.onBack,
  }) : super(key: key);

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  String searchProject = '';
  String searchNote = '';
  GroupType groupType = GroupType.day;

  final dateFormat = DateFormat('yyyy-MM-dd');
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _projectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memberData = widget.memberDoc.data() as Map<String, dynamic>;
    final userId = widget.memberDoc.id;
    final userName = '${memberData['firstName'] ?? ''} ${memberData['surname'] ?? ''}';

    BoxDecoration pillDecoration = BoxDecoration(
      border: Border.all(
        color: isDark ? Colors.white24 : Colors.black26, 
        width: 1
      ),
      color: isDark 
        ? colors.cardColorDark
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Tabs remain visible at the top, let parent handle color changes/press logic ---
        // Main header with name and working status icon
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10, left: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  color: colors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              _StatusIcon(companyId: widget.companyId, userId: userId),
            ],
          ),
        ),
        _TotalsHeader(companyId: widget.companyId, userId: userId),
        const SizedBox(height: 10),

        // Add New Session button
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddNewSessionDialog(
                    companyId: widget.companyId,
                    userId: userId,
                    userName: userName,
                    onSessionAdded: () => setState(() {}),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.whiteTextOnBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search/Filter line (same as history module)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colors.cardColorDark : Colors.white,
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
              // From and To date pickers
              final fromDatePicker = InkWell(
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
              );

              final toDatePicker = InkWell(
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

              // Project and Note filters
              final projectBox = Container(
                height: kFilterHeight,
                width: 150,
                alignment: Alignment.centerLeft,
                decoration: pillDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _projectController,
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
                  controller: _noteController,
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

              // Refresh button
              final refreshBtn = Container(
                height: kFilterHeight,
                                    decoration: BoxDecoration(
                      color: isDark 
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.primary.withOpacity(0.1),
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
                      _projectController.clear();
                      _noteController.clear();
                    });
                  },
                ),
              );

              // Check if we need to wrap (when screen is too narrow)
              final needsWrap = constraints.maxWidth < 800;
              
              if (needsWrap) {
                // Wrap layout for small screens
                return Wrap(
                  spacing: kFilterSpacing,
                  runSpacing: 8,
                  children: [
                    fromDatePicker,
                    toDatePicker,
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
                    fromDatePicker,
                    const SizedBox(width: kFilterSpacing),
                    toDatePicker,
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
        const SizedBox(height: 10),

        Expanded(
          child: _LogsTable(
            companyId: widget.companyId,
            userId: userId,
            fromDate: fromDate,
            toDate: toDate,
            searchProject: searchProject,
            searchNote: searchNote,
            groupType: groupType,
            onAction: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String companyId;
  final String userId;

  const _StatusIcon({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: todayStr)
          .snapshots(),
      builder: (context, snapshot) {
        bool isWorking = false;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final hasBegin = data['begin'] != null;
            final hasEnd = data['end'] != null;
            if (hasBegin && !hasEnd) {
              isWorking = true;
              break;
            }
          }
        }
        String status = isWorking ? '🟢 Working' : '🔴 Not working';
        return Text(status, style: const TextStyle(fontSize: 18));
      },
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final String companyId;
  final String userId;

  const _TotalsHeader({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .get(),
      builder: (context, snapshot) {
        double totalWork = 0;
        double totalExpenses = 0;
        double currentWeekWork = 0;
        int approvedCount = 0;
        int rejectedCount = 0;
        int pendingCount = 0;

        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final workMinutes = (data['duration_minutes'] ?? 0).toDouble();
            totalWork += workMinutes;
            
            // Calculate current week work
            final begin = (data['begin'] as Timestamp?)?.toDate();
            if (begin != null && begin.isAfter(startOfWeekDate)) {
              currentWeekWork += workMinutes;
            }
            
            final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
            totalExpenses += expenses.values.fold<double>(0, (sum, e) => sum + (e is num ? e : 0));
            
            final approvedRaw = data['approved'];
            final rejectedRaw = data['rejected'];
            final approvedAfterEditRaw = data['approvedAfterEdit'];
            
            final isApproved = approvedRaw == true || approvedRaw == 1 || approvedRaw == '1';
            final isRejected = rejectedRaw == true || rejectedRaw == 1 || rejectedRaw == '1';
            final isApprovedAfterEdit = approvedAfterEditRaw == true || approvedAfterEditRaw == 1 || approvedAfterEditRaw == '1';
            
            if (isApprovedAfterEdit || isApproved) {
              approvedCount++;
            } else if (isRejected) {
              rejectedCount++;
            } else {
              pendingCount++;
            }
          }
        }
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnapshot) {
            Widget overtimeWidget = const SizedBox.shrink();
            
            if (userSnapshot.hasData) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final weeklyHours = (userData?['weeklyHours'] ?? 40) as int;
              final weeklyMinutes = weeklyHours * 60;
              final overtimeMinutes = currentWeekWork - weeklyMinutes;
              
              if (overtimeMinutes != 0) {
                final isOvertime = overtimeMinutes > 0;
                final color = isOvertime ? Colors.green : Colors.red;
                final sign = isOvertime ? '+' : '';
                
                overtimeWidget = Text(
                  'Overtime: $sign${_fmtH(overtimeMinutes.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                );
              }
            }
            
            return Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('Total Work: ${_fmtH(totalWork)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (overtimeWidget is! SizedBox) overtimeWidget,
                Text('Total Expenses: ${totalExpenses.toStringAsFixed(2)} CHF', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Approved: $approvedCount | Rejected: $rejectedCount | Pending: $pendingCount', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            );
          },
        );
      },
    );
  }
}

class _LogsTable extends StatefulWidget {
  final String companyId;
  final String userId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String searchProject;
  final String searchNote;
  final GroupType groupType;
  final VoidCallback onAction;

  const _LogsTable({
    required this.companyId,
    required this.userId,
    this.fromDate,
    this.toDate,
    required this.searchProject,
    required this.searchNote,
    required this.groupType,
    required this.onAction,
  });

  @override
  State<_LogsTable> createState() => _LogsTableState();
}

class _LogsTableState extends State<_LogsTable> {
  List<String> _allProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .get();
    setState(() {
      _allProjects = snap.docs.map((doc) => doc['name']?.toString() ?? '').toList();
    });
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, Map<String, dynamic> sessionData) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final begin = (sessionData['begin'] as Timestamp?)?.toDate();
    final end = (sessionData['end'] as Timestamp?)?.toDate();
    final project = sessionData['project'] ?? '';
    final sessionDate = begin != null ? DateFormat('yyyy-MM-dd').format(begin) : '';
    final timeRange = begin != null && end != null 
        ? '${DateFormat('HH:mm').format(begin)} - ${DateFormat('HH:mm').format(end)}'
        : '';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundDark,
        title: Text(
          'Delete Session',
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this session?',
              style: TextStyle(color: colors.textColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sessionDate.isNotEmpty)
                    Text('Date: $sessionDate', style: TextStyle(color: colors.textColor)),
                  if (timeRange.isNotEmpty)
                    Text('Time: $timeRange', style: TextStyle(color: colors.textColor)),
                  if (project.isNotEmpty)
                    Text('Project: $project', style: TextStyle(color: colors.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.red,
              foregroundColor: colors.whiteTextOnBlue,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper for formatting Duration as HH:MMh
  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  int _weekNumber(DateTime date) {
    // ISO 8601: Week 1 is the week containing January 4th
    final jan4 = DateTime(date.year, 1, 4);
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final jan4StartOfWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
    final weekNumber = ((startOfWeek.difference(jan4StartOfWeek).inDays) / 7).floor() + 1;
    return weekNumber;
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .collection('all_logs')
          .orderBy('begin', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;

        // Apply filters
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final begin = (data['begin'] as Timestamp?)?.toDate();
          final project = (data['project'] ?? '').toString().toLowerCase();
          final note = (data['note'] ?? '').toString().toLowerCase();
          final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
          final expString = expenses.entries.map((e) => '${e.key}:${e.value}').join(',').toLowerCase();

          // Date range filter
          if (widget.fromDate != null && begin != null && begin.isBefore(widget.fromDate!)) return false;
          if (widget.toDate != null && begin != null && begin.isAfter(widget.toDate!)) return false;

          // Project filter
          if (widget.searchProject.isNotEmpty &&
              !project.contains(widget.searchProject.toLowerCase())) {
            return false;
          }

          // Note filter (includes expenses)
          if (widget.searchNote.isNotEmpty &&
              !note.contains(widget.searchNote.toLowerCase()) &&
              !expString.contains(widget.searchNote.toLowerCase())) {
            return false;
          }

          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No time logs found for this worker.'));
        }

        // ==== GROUPING LOGIC STARTS HERE ====
        // Convert to models for easier handling
        List<_HistoryEntry> entries = docs.map((doc) {
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
          final perDiem = perDiemRaw == true || perDiemRaw == 1 || perDiemRaw == '1';
          final expensesMap = Map<String, dynamic>.from(data['expenses'] ?? {});
          double totalExpense = 0.0;
          for (var v in expensesMap.values) {
            if (v is num) {
              totalExpense += v.toDouble();
            } else if (v is String) {
              final parsed = double.tryParse(v);
              if (parsed != null) totalExpense += parsed;
            } else if (v is bool) {
              // Skip boolean values
              continue;
            }
          }

          return _HistoryEntry(
            doc: doc,
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

        // ==== GROUPING LOGIC ====
        // Grouping map
        Map<String, List<_HistoryEntry>> grouped = {};

        for (var entry in entries) {
          String key = '';
          if (entry.begin == null) key = 'Unknown';
          else {
            switch (widget.groupType) {
              case GroupType.day:
                key = DateFormat('yyyy-MM-dd').format(entry.begin!);
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
            if (widget.groupType == GroupType.day) {
              try {
                return DateTime.parse(b).compareTo(DateTime.parse(a));
              } catch (_) {}
            } else if (widget.groupType == GroupType.year) {
              return int.parse(b).compareTo(int.parse(a));
            } else if (widget.groupType == GroupType.month) {
              try {
                final fa = DateFormat('MMMM yyyy').parse(a);
                final fb = DateFormat('MMMM yyyy').parse(b);
                return fb.compareTo(fa);
              } catch (_) {}
            } else if (widget.groupType == GroupType.week) {
              final wa = int.tryParse(a.split(' ')[1].replaceAll(',', '')) ?? 0;
              final wb = int.tryParse(b.split(' ')[1].replaceAll(',', '')) ?? 0;
              final ya = int.tryParse(a.split(',').last.trim()) ?? 0;
              final yb = int.tryParse(b.split(',').last.trim()) ?? 0;
              return yb != ya ? yb.compareTo(ya) : wb.compareTo(wa);
            }
            return a.compareTo(b);
          });

        // ==== UI ====
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final appColors = Theme.of(context).extension<AppColors>()!;
        final expenseFormat = NumberFormat.currency(symbol: "CHF ", decimalDigits: 2);

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          cacheExtent: 1000,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemCount: sortedKeys.length,
          itemBuilder: (context, groupIdx) {
            final groupKey = sortedKeys[groupIdx];
            final groupList = grouped[groupKey]!;

            final groupTotal = groupList.fold<Duration>(
                Duration.zero, (sum, e) => sum + e.duration);
            final groupExpense = groupList.fold<double>(
                0.0, (sum, e) {
                  if (e.expense.isNaN) return sum;
                  return sum + e.expense;
                });

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: isDark ? 0 : 4,
              color: isDark ? appColors.cardColorDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                   ...groupList.map((entry) {
                     final data = entry.doc.data() as Map<String, dynamic>;
                     final approvedRaw = data['approved'];
                     final rejectedRaw = data['rejected'];
                     final approvedAfterEditRaw = data['approvedAfterEdit'];
                     
                     final isApproved = approvedRaw == true || approvedRaw == 1 || approvedRaw == '1';
                     final isRejected = rejectedRaw == true || rejectedRaw == 1 || rejectedRaw == '1';
                     final isApprovedAfterEdit = approvedAfterEditRaw == true || approvedAfterEditRaw == 1 || approvedAfterEditRaw == '1';
                     
                     return ListTile(
                       title: Text(
                         (entry.begin != null && entry.end != null)
                             ? '${DateFormat('yyyy-MM-dd').format(entry.begin!)}  ${DateFormat('HH:mm').format(entry.begin!)} - ${DateFormat('HH:mm').format(entry.end!)}'
                             : entry.sessionDate,
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           color: isDark ? const Color(0xFFCCCCCC) : Colors.black87,
                         ),
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
                                 children: entry.expensesMap.entries.map((e) {
                                   double expenseValue = 0.0;
                                   if (e.value is num) {
                                     expenseValue = (e.value as num).toDouble();
                                   } else if (e.value is String) {
                                     expenseValue = double.tryParse(e.value as String) ?? 0.0;
                                   } else if (e.value is bool) {
                                     // Skip boolean values
                                     return const SizedBox.shrink();
                                   }
                                   return Text('${e.key}: ${expenseFormat.format(expenseValue)}',
                                     style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 15),
                                   );
                                 }).toList(),
                               ),
                             ),
                           const SizedBox(height: 8),
                           // Approval icons for this specific session
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               // Approve
                               if (!isApproved && !isRejected && !isApprovedAfterEdit)
                                 IconButton(
                                   icon: const Icon(Icons.check, color: Colors.green, size: 20),
                                   tooltip: 'Approve',
                                   onPressed: () async {
                                     await entry.doc.reference.update({
                                       'approved': true,
                                       'approvedBy': widget.userId,
                                       'approvedAt': FieldValue.serverTimestamp(),
                                     });
                                     widget.onAction();
                                   },
                                 ),
                               // Reject
                               if (!isApproved && !isRejected && !isApprovedAfterEdit)
                                 IconButton(
                                   icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                   tooltip: 'Reject',
                                   onPressed: () async {
                                     await entry.doc.reference.update({
                                       'rejected': true,
                                       'rejectedBy': widget.userId,
                                       'rejectedAt': FieldValue.serverTimestamp(),
                                     });
                                     widget.onAction();
                                   },
                                 ),
                               // Edit
                               if (!isApproved && !isRejected && !isApprovedAfterEdit)
                                 IconButton(
                                   icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                   tooltip: 'Edit',
                                   onPressed: () async {
                                     await showDialog(
                                       context: context,
                                       builder: (_) => _EditLogDialog(
                                         logDoc: entry.doc,
                                         projects: _allProjects,
                                         onSaved: widget.onAction,
                                       ),
                                     );
                                   },
                                 ),
                               // Delete
                               if (!isApproved && !isRejected && !isApprovedAfterEdit)
                                 IconButton(
                                   icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                   tooltip: 'Delete',
                                   onPressed: () async {
                                     final confirmed = await _showDeleteConfirmation(context, data);
                                     if (confirmed == true) {
                                       await entry.doc.reference.delete();
                                       widget.onAction();
                                       if (context.mounted) {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           const SnackBar(
                                             content: Text('Session deleted successfully'),
                                             backgroundColor: Colors.green,
                                           ),
                                         );
                                       }
                                     }
                                   },
                                 ),
                               // Status indicators
                               if (isApprovedAfterEdit)
                                 const Icon(Icons.verified, color: Colors.orange, size: 20)
                               else if (isApproved)
                                 const Icon(Icons.verified, color: Colors.green, size: 20)
                               else if (isRejected)
                                 const Icon(Icons.cancel, color: Colors.red, size: 20),
                             ],
                           ),
                         ],
                       ),
                     );
                   }).toList(),
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
    );
  }
}

class _EditLogDialog extends StatefulWidget {
  final DocumentSnapshot logDoc;
  final List<String> projects;
  final VoidCallback onSaved;

  const _EditLogDialog({
    required this.logDoc,
    required this.projects,
    required this.onSaved,
  });

  @override
  State<_EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<_EditLogDialog> {
  late TextEditingController _noteCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late Map<String, dynamic> _expenses;
  String _approvalNote = '';
  String? _projectValue;
  bool _projectError = false;

  @override
  void initState() {
    final data = widget.logDoc.data() as Map<String, dynamic>;
    _noteCtrl = TextEditingController(text: data['note'] ?? '');
    _startCtrl = TextEditingController(
      text: (data['begin'] as Timestamp?) != null
          ? DateFormat('HH:mm').format((data['begin'] as Timestamp).toDate())
          : '',
    );
    _endCtrl = TextEditingController(
      text: (data['end'] as Timestamp?) != null
          ? DateFormat('HH:mm').format((data['end'] as Timestamp).toDate())
          : '',
    );
    _expenses = Map<String, dynamic>.from(data['expenses'] ?? {});
    _approvalNote = data['approvalNote'] ?? '';
    final projectValue = data['project']?.toString();
    if (projectValue != null && widget.projects.contains(projectValue)) {
      _projectValue = projectValue;
    } else {
      _projectValue = null;
    }
    super.initState();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }



  Future<void> _showExpensePopup() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(_expenses);
    bool tempPerDiem = tempExpenses.containsKey('Per diem');
    
    // Check if per diem is used elsewhere on this day
    final data = widget.logDoc.data() as Map<String, dynamic>;
    final begin = (data['begin'] as Timestamp?)?.toDate();
    final sessionDate = begin != null ? DateFormat('yyyy-MM-dd').format(begin) : '';
    
    bool perDiemUsedElsewhere = false;
    if (sessionDate.isNotEmpty) {
      try {
        final logRef = widget.logDoc.reference;
        final userRef = logRef.parent.parent;
        final companyRef = userRef?.parent;
        
        if (userRef == null || companyRef == null) return;
        
        final companyId = companyRef.id;
        final userId = userRef.id;
        
        final snapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId) // company ID
            .collection('users')
            .doc(userId) // user ID
            .collection('all_logs')
            .where('sessionDate', isEqualTo: sessionDate)
            .get();
        
        for (var doc in snapshot.docs) {
          if (doc.id != widget.logDoc.id) { // Skip current session
            final docData = doc.data();
            final expenses = Map<String, dynamic>.from(docData['expenses'] ?? {});
            if (expenses.containsKey('Per diem')) {
              perDiemUsedElsewhere = true;
              break;
            }
          }
        }
      } catch (e) {
        print('Error checking per diem: $e');
      }
    }
    
    final bool perDiemAvailable = !perDiemUsedElsewhere;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool canAddExpense() {
              final name = nameCtrl.text.trim();
              final amountStr = amountCtrl.text.trim();
              final amount = double.tryParse(amountStr.replaceAll(',', '.'));
              return name.isNotEmpty &&
                  amountStr.isNotEmpty &&
                  amount != null &&
                  amount > 0 &&
                  !tempExpenses.containsKey(name) &&
                  name != 'Per diem';
            }

            void addExpense() {
              final name = nameCtrl.text.trim();
              final amountStr = amountCtrl.text.trim();
              if (!canAddExpense()) return;
              setStateDialog(() {
                tempExpenses[name] = double.parse(amountStr.replaceAll(',', '.'));
                nameCtrl.clear();
                amountCtrl.clear();
              });
            }

            void handlePerDiemChange(bool? checked) {
              setStateDialog(() {
                tempPerDiem = checked ?? false;
                if (tempPerDiem) {
                  tempExpenses['Per diem'] = 16.00;
                } else {
                  tempExpenses.remove('Per diem');
                }
              });
            }

            void handleExpenseChange(String key, bool? checked) {
              if (checked == false) {
                setStateDialog(() => tempExpenses.remove(key));
              }
            }

            final List<String> otherExpenseKeys =
                tempExpenses.keys.where((k) => k != 'Per diem').toList();
            final List<Widget> expenseWidgets = [
              for (final key in otherExpenseKeys)
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (checked) => handleExpenseChange(key, checked),
                      activeColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Text(
                      key,
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      '${(tempExpenses[key] as num).toStringAsFixed(2)} CHF',
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16),
                    ),
                  ],
                ),
              Row(
                children: [
                  Checkbox(
                    value: tempPerDiem,
                    onChanged: perDiemAvailable ? handlePerDiemChange : null,
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Text(
                    'Per Diem',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                      color: perDiemAvailable ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                  if (perDiemUsedElsewhere)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: "Per diem already used in another session today",
                        child: Icon(Icons.info_outline, color: Colors.grey, size: 18),
                      ),
                    ),
                  const Spacer(),
                  const Text('16.00 CHF',
                      style: TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16)),
                ],
              ),
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Expenses'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...expenseWidgets,
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                            onSubmitted: (_) => canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: amountCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Amount',
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setStateDialog(() {}),
                            onSubmitted: (_) => canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: canAddExpense() ? addExpense : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: colors.whiteTextOnBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Add', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () => Navigator.pop(context, tempExpenses),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (result != null) {
      setState(() {
        _expenses = Map<String, dynamic>.from(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  
    return AlertDialog(
      title: const Text('Edit Time Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start time
            TextField(
              controller: _startCtrl,
              decoration: const InputDecoration(labelText: 'Start Time (HH:mm)'),
              keyboardType: TextInputType.datetime,
            ),
            // End time
            TextField(
              controller: _endCtrl,
              decoration: const InputDecoration(labelText: 'End Time (HH:mm)'),
              keyboardType: TextInputType.datetime,
            ),
            // Project (dropdown)
            DropdownButtonFormField<String>(
              value: _projectValue,
              isExpanded: true,
              items: widget.projects.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _projectValue = val;
                  _projectError = false;
                });
              },
              decoration: const InputDecoration(labelText: 'Project'),
            ),
            if (_projectError)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'No Project selected!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            // Note
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            // Expenses (using standard expense popup)
            GestureDetector(
              onTap: _showExpensePopup,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expenses:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (_expenses.isEmpty)
                        const Text('Tap to add', style: TextStyle(color: Colors.grey))
                      else
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (var entry in _expenses.entries)
                                if (entry.key != 'Per diem')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text('${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF', 
                                      style: const TextStyle(fontSize: 13)),
                                  ),
                              if (_expenses.containsKey('Per diem'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text('Per diem ${(_expenses['Per diem'] as num).toStringAsFixed(2)} CHF', 
                                    style: const TextStyle(fontSize: 13)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Approval note (optional)
            TextField(
              decoration: const InputDecoration(labelText: 'Approval Note (optional)'),
              onChanged: (v) => _approvalNote = v.trim(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Save & Approve'),
          onPressed: () async {
            // Validate time and project
            DateTime start, end;
            try {
              final baseDay = (widget.logDoc['begin'] as Timestamp).toDate();
              final sParts = _startCtrl.text.split(':');
              final eParts = _endCtrl.text.split(':');
              start = DateTime(baseDay.year, baseDay.month, baseDay.day, int.parse(sParts[0]), int.parse(sParts[1]));
              end = DateTime(baseDay.year, baseDay.month, baseDay.day, int.parse(eParts[0]), int.parse(eParts[1]));
              if (!end.isAfter(start)) throw 'End before start';
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid start/end time')));
              return;
            }
            if (_projectValue == null || _projectValue!.trim().isEmpty) {
              setState(() => _projectError = true);
              return;
            }
            int durationMins = end.difference(start).inMinutes;

            await widget.logDoc.reference.update({
              'begin': Timestamp.fromDate(start),
              'end': Timestamp.fromDate(end),
              'duration_minutes': durationMins,
              'note': _noteCtrl.text.trim(),
              'expenses': _expenses,
              'project': _projectValue,
              'projectId': _projectValue, // Add projectId field
              'approvalNote': _approvalNote,
              'approved': false, // Set to false since this is approvedAfterEdit
              'approvedAt': FieldValue.serverTimestamp(),
              'edited': true,
              'approvedAfterEdit': true, // This is the primary approval status for edited sessions
            });
            widget.onSaved();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

String _fmtH(num mins) {
  final h = (mins ~/ 60).toString().padLeft(2, '0');
  final m = (mins % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

// Helper class for history entry
class _HistoryEntry {
  final DocumentSnapshot doc;
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
    required this.doc,
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
