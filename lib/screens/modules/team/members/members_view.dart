import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/overtime_calculation_service.dart';
import 'add_new_session.dart';
part 'status_icon.part.dart';
part 'totals_header.part.dart';
part 'helpers.part.dart';
part 'edit_log_dialog.part.dart';
part 'history_entry.part.dart';

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
    super.key,
    required this.companyId,
    required this.memberDoc,
    this.onBack,
  });

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  String searchProject = '';
  String searchNote = '';
  GroupType groupType = GroupType.day;
  bool _isCardExpanded = false; // New state for card expansion

  final dateFormat = DateFormat('dd/MM/yyyy');
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
    final userName =
        '${memberData['firstName'] ?? ''} ${memberData['surname'] ?? ''}';

    BoxDecoration pillDecoration = BoxDecoration(
      border:
          Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 1),
      color: isDark ? colors.cardColorDark : Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
    );

    TextStyle pillTextStyle = TextStyle(
      fontSize: kFilterFontSize,
      fontWeight: FontWeight.w500,
      color: isDark
          ? Colors.white.withValues(alpha: 0.87)
          : Colors.black.withValues(alpha: 0.87),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible User Info and Filter Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colors.cardColorDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Header with name and expand/collapse button
              InkWell(
                onTap: () {
                  setState(() => _isCardExpanded = !_isCardExpanded);
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      left: 16,
                      right: 16), // Reduced top padding
                  child: Row(
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: colors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Reduced from 22 to 18
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusIcon(
                          companyId: widget.companyId, userId: userId),
                      const SizedBox(width: 8),
                      Icon(
                        _isCardExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: colors.primaryBlue,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              if (_isCardExpanded) ...[
                // Subtle divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isDark ? Colors.white12 : Colors.black12,
                ),

                // User details and filters
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // User status and totals
                      Row(
                        children: [
                          Expanded(
                              child: _TotalsHeader(
                                  companyId: widget.companyId, userId: userId)),
                        ],
                      ),

                      const SizedBox(height: 16),

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
                                  onSessionAdded: () {
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(
                                AppLocalizations.of(context)!.addNewSession),
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

                      // Filter controls
                      LayoutBuilder(
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
                              if (picked != null) {
                                setState(() => fromDate = picked);
                              }
                            },
                            child: Container(
                              height: kFilterHeight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              decoration: pillDecoration,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range,
                                      color: theme.colorScheme.primary,
                                      size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    fromDate == null
                                        ? AppLocalizations.of(context)!.from
                                        : dateFormat.format(fromDate!),
                                    style: TextStyle(
                                      color: fromDate == null
                                          ? theme.colorScheme.primary
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.87)
                                              : Colors.black
                                                  .withValues(alpha: 0.87)),
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
                              if (picked != null) {
                                setState(() => toDate = picked);
                              }
                            },
                            child: Container(
                              height: kFilterHeight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              decoration: pillDecoration,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range,
                                      color: theme.colorScheme.primary,
                                      size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    toDate == null
                                        ? AppLocalizations.of(context)!.to
                                        : dateFormat.format(toDate!),
                                    style: TextStyle(
                                      color: toDate == null
                                          ? theme.colorScheme.primary
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.87)
                                              : Colors.black
                                                  .withValues(alpha: 0.87)),
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
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 22),
                                items: [
                                  DropdownMenuItem(
                                    value: GroupType.day,
                                    child:
                                        Text(AppLocalizations.of(context)!.day),
                                  ),
                                  DropdownMenuItem(
                                    value: GroupType.week,
                                    child: Text(
                                        AppLocalizations.of(context)!.week),
                                  ),
                                  DropdownMenuItem(
                                    value: GroupType.month,
                                    child: Text(
                                        AppLocalizations.of(context)!.month),
                                  ),
                                  DropdownMenuItem(
                                    value: GroupType.year,
                                    child: Text(
                                        AppLocalizations.of(context)!.year),
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
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: TextField(
                              controller: _projectController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.project,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: pillTextStyle,
                              onChanged: (v) =>
                                  setState(() => searchProject = v.trim()),
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
                                hintText: AppLocalizations.of(context)!.note,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: pillTextStyle,
                              onChanged: (v) =>
                                  setState(() => searchNote = v.trim()),
                            ),
                          );

                          // Refresh button
                          final refreshBtn = Container(
                            height: kFilterHeight,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.2)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.refresh,
                                  color: theme.colorScheme.primary, size: 24),
                              tooltip:
                                  AppLocalizations.of(context)!.clearFilters,
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
                            // Simple responsive layout with guaranteed left alignment
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date pickers - allow wrapping when needed
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    if (innerConstraints.maxWidth < 300) {
                                      // Stack vertically if too narrow
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          fromDatePicker,
                                          const SizedBox(height: 8),
                                          toDatePicker,
                                        ],
                                      );
                                    } else {
                                      // Side by side if enough space
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          fromDatePicker,
                                          const SizedBox(width: kFilterSpacing),
                                          toDatePicker,
                                        ],
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Controls row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    groupDropdown,
                                    const SizedBox(width: kFilterSpacing),
                                    refreshBtn,
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Search fields - use Wrap only for these if needed
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    if (innerConstraints.maxWidth < 400) {
                                      // Stack vertically if too narrow
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          projectBox,
                                          const SizedBox(height: 8),
                                          noteBox,
                                        ],
                                      );
                                    } else {
                                      // Side by side if enough space
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          projectBox,
                                          const SizedBox(width: kFilterSpacing),
                                          noteBox,
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          } else {
                            // Single row layout for larger screens
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fromDatePicker,
                                const SizedBox(width: kFilterSpacing),
                                toDatePicker,
                                const SizedBox(width: kFilterSpacing),
                                groupDropdown,
                                const SizedBox(width: kFilterSpacing),
                                refreshBtn,
                                const SizedBox(width: kFilterSpacing),
                                Expanded(child: projectBox),
                                const SizedBox(width: kFilterSpacing),
                                Expanded(child: noteBox),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
            onAction: () {
              setState(() {});
            },
          ),
        ),
      ],
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
      _allProjects =
          snap.docs.map((doc) => doc['name']?.toString() ?? '').toList();
    });
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final begin = (sessionData['begin'] as Timestamp?)?.toDate();
    final end = (sessionData['end'] as Timestamp?)?.toDate();
    final project = sessionData['project'] ?? '';
    final sessionDate =
        begin != null ? DateFormat('dd/MM/yyyy').format(begin) : '';
    final timeRange = begin != null && end != null
        ? '${DateFormat('HH:mm').format(begin)} - ${DateFormat('HH:mm').format(end)}'
        : '';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundDark,
        title: Text(
          AppLocalizations.of(context)!.deleteSession,
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
                    Text(
                        '${AppLocalizations.of(context)!.sessionDate}: $sessionDate',
                        style: TextStyle(color: colors.textColor)),
                  if (timeRange.isNotEmpty)
                    Text('${AppLocalizations.of(context)!.time}: $timeRange',
                        style: TextStyle(color: colors.textColor)),
                  if (project.isNotEmpty)
                    Text('${AppLocalizations.of(context)!.project}: $project',
                        style: TextStyle(color: colors.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete this session?',
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
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: colors.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.red,
              foregroundColor: colors.whiteTextOnBlue,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptManagerNote(BuildContext context, String title) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool showError = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: colors.backgroundDark,
            title: Text(title, style: TextStyle(color: colors.textColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.note,
                    errorText: showError ? 'Note Required !' : null,
                  ),
                  onChanged: (_) {
                    if (showError && ctrl.text.trim().isNotEmpty) {
                      setState(() => showError = false);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: Text(AppLocalizations.of(context)!.cancel,
                    style: TextStyle(color: colors.textColor)),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = ctrl.text.trim();
                  if (value.isEmpty) {
                    setState(() => showError = true);
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryBlue,
                  foregroundColor: colors.whiteTextOnBlue,
                ),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendManagerNoteToUser({
    required DocumentReference logRef,
    required String note,
    required String type,
  }) async {
    try {
      final userRef = logRef.parent.parent; // users/{userId}
      final companyRef = userRef?.parent; // companies/{companyId}/users
      if (userRef == null || companyRef == null || note.isEmpty) {
        return;
      }
      await userRef.collection('manager_notes').add({
        'note': note,
        'type': type, // rejected | deleted
        'logId': logRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
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

  // Helper for formatting overtime hours consistently
  String _formatOvertimeHours(double hours) {
    if (hours == 0) {
      return '0m';
    }

    final isNegative = hours < 0;
    final absHours = hours.abs();
    final h = absHours.floor();
    final m = ((absHours - h) * 60).round();

    if (h > 0) {
      return '${isNegative ? '-' : ''}${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${isNegative ? '-' : ''}${m}m';
  }

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

  String _getDayIndicator(String dateKey) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateKey);
      final weekday = date.weekday;
      switch (weekday) {
        case 1:
          return 'Mo';
        case 2:
          return 'Tu';
        case 3:
          return 'We';
        case 4:
          return 'Th';
        case 5:
          return 'Fr';
        case 6:
          return 'Sa';
        case 7:
          return 'Su';
        default:
          return '';
      }
    } catch (e) {
      return '';
    }
  }

  bool _isWeekend(String dateKey) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateKey);
      return date.weekday >= 6; // Saturday = 6, Sunday = 7
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _calculateDailyOvertime(
      String userId, String date) async {
    try {
      // Convert EU date format (dd/MM/yyyy) to ISO format (yyyy-MM-dd) for the service
      final euDate = DateFormat('dd/MM/yyyy').parse(date);
      final isoDate = DateFormat('yyyy-MM-dd').format(euDate);

      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
        fromDate: euDate,
        toDate: euDate.add(const Duration(days: 1)),
      );

      // Find the calculation details for this specific date
      final calculationDetails =
          result['calculationDetails'] as List<Map<String, dynamic>>? ?? [];
      for (final dayDetail in calculationDetails) {
        if (dayDetail['date'] == isoDate) {
          return {
            'overtimeMinutes': dayDetail['overtimeMinutes'] ?? 0,
            'overtimeHours': dayDetail['overtimeHours'] ?? '0.00',
            'reason': '',
            'expectedHours': dayDetail['expectedHours'] ?? '8.00',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _calculateWeeklyOvertime(
      String userId, String weekKey) async {
    try {
      // Parse week key format: "Week X, YYYY"
      final parts = weekKey.split(', ');
      final year = int.parse(parts[1]);
      final weekNumber = int.parse(parts[0].split(' ')[1]);

      // Calculate the start date of the week
      final jan4 = DateTime(year, 1, 4);
      final startOfYear = jan4.subtract(Duration(days: jan4.weekday - 1));
      final weekStart = startOfYear.add(Duration(days: (weekNumber - 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Removed debug prints

      // Calculate overtime for the entire week at once (not from user start date)
      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
        fromDate: weekStart,
        toDate: weekEnd,
      );

      final calculationDetails =
          result['calculationDetails'] as List<Map<String, dynamic>>? ?? [];
      int totalOvertimeMinutes = 0;

      for (final dayDetail in calculationDetails) {
        final dateStr = dayDetail['date'] as String?;
        if (dateStr != null) {
          // Parse the date for proper comparison
          final dayDate = DateTime.parse(dateStr);
          // EU format conversion removed (unused)
          // Only include days that are within the week range
          if (dayDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              dayDate.isBefore(weekEnd)) {
            final dayOvertimeMinutes =
                dayDetail['overtimeMinutes'] as int? ?? 0;
            totalOvertimeMinutes += dayOvertimeMinutes;
          } else {}
        }
      }

      final totalOvertimeHours = (totalOvertimeMinutes / 60).toStringAsFixed(2);
      final reason = '';

      // Removed debug prints

      return {
        'overtimeMinutes': totalOvertimeMinutes,
        'overtimeHours': totalOvertimeHours,
        'reason': reason,
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _calculateMonthlyOvertime(
      String userId, String monthKey) async {
    try {
      // Parse month key format: "MMMM YYYY"
      final monthDate = DateFormat('MMMM yyyy').parse(monthKey);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 1);

      // Calculate overtime for the entire month at once (not from user start date)
      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
        fromDate: monthStart,
        toDate: monthEnd,
      );

      final calculationDetails =
          result['calculationDetails'] as List<Map<String, dynamic>>? ?? [];
      int totalOvertimeMinutes = 0;

      for (final dayDetail in calculationDetails) {
        final dayOvertimeMinutes = dayDetail['overtimeMinutes'] as int? ?? 0;
        totalOvertimeMinutes += dayOvertimeMinutes;
      }

      final totalOvertimeHours = (totalOvertimeMinutes / 60).toStringAsFixed(2);
      final reason = '';

      return {
        'overtimeMinutes': totalOvertimeMinutes,
        'overtimeHours': totalOvertimeHours,
        'reason': reason,
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _calculateYearlyOvertime(
      String userId, String yearKey) async {
    try {
      // Parse year key format: "YYYY"
      final year = int.parse(yearKey);
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year + 1, 1, 1);

      // Calculate overtime for the entire year at once (not from user start date)
      final result = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
        fromDate: yearStart,
        toDate: yearEnd,
      );

      final calculationDetails =
          result['calculationDetails'] as List<Map<String, dynamic>>? ?? [];
      int totalOvertimeMinutes = 0;

      for (final dayDetail in calculationDetails) {
        final dayOvertimeMinutes = dayDetail['overtimeMinutes'] as int? ?? 0;
        totalOvertimeMinutes += dayOvertimeMinutes;
      }

      final totalOvertimeHours = (totalOvertimeMinutes / 60).toStringAsFixed(2);
      final reason = '';

      return {
        'overtimeMinutes': totalOvertimeMinutes,
        'overtimeHours': totalOvertimeHours,
        'reason': reason,
      };
    } catch (e) {
      return null;
    }
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
          final expString = expenses.entries
              .map((e) => '${e.key}:${e.value}')
              .join(',')
              .toLowerCase();

          // Date range filter
          if (widget.fromDate != null &&
              begin != null &&
              begin.isBefore(widget.fromDate!)) {
            return false;
          }
          if (widget.toDate != null &&
              begin != null &&
              begin.isAfter(widget.toDate!)) {
            return false;
          }

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
          return Center(
              child: Text(AppLocalizations.of(context)!.noTimeLogsFound));
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
          final perDiem =
              perDiemRaw == true || perDiemRaw == 1 || perDiemRaw == '1';
          final expensesMap = Map<String, dynamic>.from(data['expenses'] ?? {});
          double totalExpense = 0.0;
          for (var v in expensesMap.values) {
            if (v is num) {
              totalExpense += v.toDouble();
            } else if (v is String) {
              final parsed = double.tryParse(v);
              if (parsed != null) {
                totalExpense += parsed;
              }
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
          if (a.begin == null) {
            return 1;
          }
          if (b.begin == null) {
            return -1;
          }
          return b.begin!.compareTo(a.begin!);
        });

        // ==== GROUPING LOGIC ====
        // Grouping map
        Map<String, List<_HistoryEntry>> grouped = {};

        for (var entry in entries) {
          String key = '';
          if (entry.begin == null) {
            key = AppLocalizations.of(context)!.unknown;
          } else {
            switch (widget.groupType) {
              case GroupType.day:
                key = DateFormat('dd/MM/yyyy').format(entry.begin!);
                break;
              case GroupType.week:
                final week = _weekNumber(entry.begin!);
                key = '${AppLocalizations.of(context)!.week} $week, ${entry.begin!.year}';
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
                // Parse EU date format (dd/MM/yyyy) for sorting
                final dateA = DateFormat('dd/MM/yyyy').parse(a);
                final dateB = DateFormat('dd/MM/yyyy').parse(b);
                return dateB.compareTo(dateA);
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
        final expenseFormat =
            NumberFormat.currency(symbol: "CHF ", decimalDigits: 2);

        return ListView.builder(
          key: ValueKey('member_history_list_${widget.userId}'),
          physics: const AlwaysScrollableScrollPhysics(),
          cacheExtent: 1000,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemCount: sortedKeys.length,
          itemBuilder: (context, groupIdx) {
            final groupKey = sortedKeys[groupIdx];
            final groupList = grouped[groupKey]!;

            final groupTotal = groupList.fold<Duration>(
                Duration.zero, (accDuration, e) => accDuration + e.duration);
            final groupExpense = groupList.fold<double>(0.0, (accAmount, e) {
              if (e.expense.isNaN) {
                return accAmount;
              }
              return accAmount + e.expense;
            });

            return Card(
              key: ValueKey('member_history_group_$groupKey'),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 0,
              color: isDark ? appColors.cardColorDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? appColors.borderColorDark : appColors.borderColorLight,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Group header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Day indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isWeekend(groupKey)
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getDayIndicator(groupKey),
                                style: TextStyle(
                                  color: _isWeekend(groupKey)
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              groupKey,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Group entries
                  ...groupList.map((entry) {
                    final data = entry.doc.data() as Map<String, dynamic>;
                    final approvedRaw = data['approved'];
                    final rejectedRaw = data['rejected'];
                    final approvedAfterEditRaw = data['approvedAfterEdit'];

                    final isApproved = approvedRaw == true ||
                        approvedRaw == 1 ||
                        approvedRaw == '1';
                    final isRejected = rejectedRaw == true ||
                        rejectedRaw == 1 ||
                        rejectedRaw == '1';
                    final isApprovedAfterEdit = approvedAfterEditRaw == true ||
                        approvedAfterEditRaw == 1 ||
                        approvedAfterEditRaw == '1';

                    return ListTile(
                      title: Text(
                        (entry.begin != null && entry.end != null)
                            ? '${_getDayIndicator(DateFormat('dd/MM/yyyy').format(entry.begin!))} ${DateFormat('dd/MM/yyyy').format(entry.begin!)}  ${DateFormat('HH:mm').format(entry.begin!)} - ${DateFormat('HH:mm').format(entry.end!)}'
                            : '${DateFormat('HH:mm').format(entry.begin!)} - ${DateFormat('HH:mm').format(entry.end!)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? const Color(0xFFCCCCCC) : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.project != '')
                            Text(
                              '${AppLocalizations.of(context)!.project}: ${entry.project}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF969696)
                                    : const Color(0xFF6A6A6A),
                              ),
                            ),
                          if (entry.duration != Duration.zero)
                            Text(
                              '${AppLocalizations.of(context)!.duration}: ${_formatDuration(entry.duration)}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF969696)
                                    : const Color(0xFF6A6A6A),
                              ),
                            ),
                          if (entry.note != '')
                            Text(
                              '${AppLocalizations.of(context)!.note}: ${entry.note}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF969696)
                                    : const Color(0xFF6A6A6A),
                              ),
                            ),
                          if (entry.perDiem)
                            Text(
                              '${AppLocalizations.of(context)!.perDiem}: ${AppLocalizations.of(context)!.yes}',
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
                                    expenseValue =
                                        double.tryParse(e.value as String) ??
                                            0.0;
                                  } else if (e.value is bool) {
                                    // Skip boolean values
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    '${_translateExpenseKey(e.key, AppLocalizations.of(context)!)}: ${expenseFormat.format(expenseValue)}',
                                    style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
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
                              if (!isApproved &&
                                  !isRejected &&
                                  !isApprovedAfterEdit)
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green, size: 20),
                                  tooltip:
                                      AppLocalizations.of(context)!.approve,
                                  onPressed: () async {
                                    await entry.doc.reference.update({
                                      'approved': true,
                                      'approvedBy': widget.userId,
                                      'approvedAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                    widget.onAction();
                                  },
                                ),
                              // Reject
                              if (!isApproved &&
                                  !isRejected &&
                                  !isApprovedAfterEdit)
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red, size: 20),
                                  tooltip: AppLocalizations.of(context)!.reject,
                                  onPressed: () async {
                                    final note = await _promptManagerNote(
                                        context,
                                        AppLocalizations.of(context)!.reject);
                                    if (note == null) {
                                      // User canceled: do not change status
                                      return;
                                    }
                                    await entry.doc.reference.update({
                                      'rejected': true,
                                      'rejectedBy': widget.userId,
                                      'rejectedAt':
                                          FieldValue.serverTimestamp(),
                                      if (note.isNotEmpty) 'managerNote': note,
                                      if (note.isNotEmpty) 'messages': FieldValue.arrayUnion([{
                                        'from': 'manager',
                                        'message': note,
                                        'timestamp': Timestamp.fromDate(DateTime.now().toUtc()),
                                        'action': 'rejected'
                                      }]),
                                    });
                                    if (note.isNotEmpty) {
                                      await _sendManagerNoteToUser(
                                          logRef: entry.doc.reference,
                                          note: note,
                                          type: 'rejected');
                                    }
                                    widget.onAction();
                                  },
                                ),
                              // Edit - for team leaders to edit any session (except approved ones, already edited+approved, and rejected ones)
                              if (!isApproved && !isApprovedAfterEdit && !isRejected)
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  tooltip: AppLocalizations.of(context)!.edit,
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => EditLogDialog(
                                        logDoc: entry.doc,
                                        projects: _allProjects,
                                        onSaved: widget.onAction,
                                        isWorkerMode: false,
                                        workerName: null,
                                      ),
                                    );
                                  },
                                ),
                              // Delete
                              if (!isApproved &&
                                  !isRejected &&
                                  !isApprovedAfterEdit)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  tooltip: AppLocalizations.of(context)!.delete,
                                  onPressed: () async {
                                    final confirmed =
                                        await _showDeleteConfirmation(
                                            context, data);
                                    if (confirmed == true) {
                                      await entry.doc.reference.delete();
                                      widget.onAction();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(
                                                    context)!
                                                .sessionDeletedSuccessfully),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              // Status indicators
                              if (isApprovedAfterEdit)
                                const Icon(Icons.verified,
                                    color: Colors.orange, size: 20)
                              else if (isApproved)
                                const Icon(Icons.verified,
                                    color: Colors.green, size: 20)
                              else if (isRejected)
                                const Icon(Icons.cancel,
                                    color: Colors.red, size: 20),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  // Group totals footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('companies')
                          .doc(widget.companyId)
                          .collection('users')
                          .doc(widget.userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        List<Widget> totalWidgets = [
                          Text(
                            '${AppLocalizations.of(context)!.totalTime}: ${_formatDuration(groupTotal)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.totalExpenses}: ${expenseFormat.format(groupExpense)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ];

                        // Add overtime calculation for all grouping types
                        if (userSnapshot.hasData) {
                          // If date range filtering is active, calculate overtime for entire range
                          if (widget.fromDate != null ||
                              widget.toDate != null) {
                            // Only show overtime for the first group when date range filtering is active
                            if (groupIdx == 0) {
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: OvertimeCalculationService
                                    .calculateOvertimeFromLogs(
                                  widget.companyId,
                                  widget.userId,
                                  fromDate: widget.fromDate,
                                  toDate: widget.toDate,
                                ),
                                builder: (context, overtimeSnapshot) {
                                  if (overtimeSnapshot.hasData &&
                                      overtimeSnapshot.data != null) {
                                    final overtimeData = overtimeSnapshot.data!;
                                    final overtimeMinutes =
                                        overtimeData['current'] as int? ?? 0;
                                    // Show overtime value
                                    final isOvertime = overtimeMinutes > 0;
                                    final color =
                                        isOvertime ? Colors.green : Colors.red;

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
                              );
                            } else {
                              // For other groups when date range filtering is active, don't show overtime
                              return Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: totalWidgets,
                              );
                            }
                          } else {
                            // Calculate overtime based on grouping type (only when no date range filtering)
                            Future<Map<String, dynamic>?> overtimeFuture;

                            switch (widget.groupType) {
                              case GroupType.day:
                                overtimeFuture = _calculateDailyOvertime(
                                    widget.userId, groupKey);
                                break;
                              case GroupType.week:
                                overtimeFuture = _calculateWeeklyOvertime(
                                    widget.userId, groupKey);
                                break;
                              case GroupType.month:
                                overtimeFuture = _calculateMonthlyOvertime(
                                    widget.userId, groupKey);
                                break;
                              case GroupType.year:
                                overtimeFuture = _calculateYearlyOvertime(
                                    widget.userId, groupKey);
                                break;
                            }

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: overtimeFuture,
                              builder: (context, overtimeSnapshot) {
                                if (overtimeSnapshot.hasData &&
                                    overtimeSnapshot.data != null) {
                                  final overtimeData = overtimeSnapshot.data!;
                                  final overtimeMinutes =
                                      overtimeData['overtimeMinutes'] as int? ??
                                          0;
                                  // Show overtime value
                                  final isOvertime = overtimeMinutes > 0;
                                  final color =
                                      isOvertime ? Colors.green : Colors.red;

                                  // Check if overtime is already added to prevent duplicates
                                  bool overtimeAlreadyAdded = false;
                                  for (final widget in totalWidgets) {
                                    if (widget is Text &&
                                        widget.data
                                                ?.toString()
                                                .contains('Overtime:') ==
                                            true) {
                                      overtimeAlreadyAdded = true;
                                      break;
                                    }
                                  }

                                  if (!overtimeAlreadyAdded) {
                                    totalWidgets.add(
                                      Text(
                                        'Overtime: ${_formatOvertimeHours(overtimeMinutes / 60)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    );
                                  } else {}

                                  // For week 27, let's show the breakdown
                                  if (groupKey.contains('Week 27')) {
                                    // calculationDetails not used; removed
                                    // Breakdown loop removed
                                  }
                                }

                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  children: totalWidgets,
                                );
                              },
                            );
                          }
                        }

                        // Return default totals if no user data
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
    );
  }
}
