import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/overtime_calculation_service.dart';
import '../../../../widgets/calendar.dart';
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
      border: Border.all(
        color: isDark ? colors.borderColorDark : colors.borderColorLight,
        width: 1,
      ),
      color: isDark ? colors.cardColorDark : Colors.white,
      borderRadius: BorderRadius.circular(10),
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
            border: Border.all(
              color: isDark ? colors.borderColorDark : colors.borderColorLight,
              width: 1,
            ),
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
                          SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
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
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Filter controls
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Date range picker widget
                          final dateRangeField = InkWell(
                              borderRadius: BorderRadius.circular(kFilterRadius),
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: colors.backgroundLight,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                                      padding: const EdgeInsets.all(10),
                                      child: CustomCalendar(
                                        initialDateRange: (fromDate != null || toDate != null)
                                            ? DateRange(
                                                startDate: fromDate,
                                                endDate: toDate,
                                              )
                                            : null,
                                        onDateRangeChanged: (newDateRange) {
                                          setState(() {
                                            fromDate = newDateRange.startDate;
                                            toDate = newDateRange.endDate;
                                            // Reset group type when selecting custom dates
                                            groupType = GroupType.day;
                                          });
                                        },
                                        minDate: DateTime(2023),
                                        maxDate: DateTime(2100),
                                        title: AppLocalizations.of(context)!.pickDates,
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
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Text(
                                            (fromDate == null && toDate == null)
                                                ? AppLocalizations.of(context)!.pickDates
                                                : (fromDate != null && toDate != null)
                                                    ? (fromDate!.isAtSameMomentAs(toDate!)
                                                        ? dateFormat.format(fromDate!)
                                                        : '${dateFormat.format(fromDate!)} - ${dateFormat.format(toDate!)}')
                                                    : (fromDate != null
                                                        ? '${dateFormat.format(fromDate!)} - ...'
                                                        : (toDate != null
                                                            ? '... - ${dateFormat.format(toDate!)}'
                                                            : AppLocalizations.of(context)!.pickDates)),
                                            style: TextStyle(
                                              color: (fromDate == null && toDate == null)
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
                                    setState(() {
                                      groupType = val;
                                      // Reset custom date range when changing group type
                                      fromDate = null;
                                      toDate = null;
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
                          final refreshBtn = SizedBox(
                            height: kFilterHeight,
                            width: kFilterHeight, // Make it square
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryBlue,
                                foregroundColor: colors.whiteTextOnBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero, // Remove padding to make it square
                              ),
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
                              child: const Icon(Icons.refresh, size: 24),
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
                                          dateRangeField,
                                        ],
                                      );
                                    } else {
                                      // Side by side if enough space
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          dateRangeField,
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
                                dateRangeField,
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
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.red,
                foregroundColor: colors.whiteTextOnBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
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
              SizedBox(
                height: 38,
                child: ElevatedButton(
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
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
      return '0h 00m';
    }

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

          // Date range filter - normalize dates to remove time components
          if (widget.fromDate != null && begin != null) {
            final beginDate = DateTime(begin.year, begin.month, begin.day);
            final fromDate = DateTime(widget.fromDate!.year, widget.fromDate!.month, widget.fromDate!.day);
            if (beginDate.isBefore(fromDate)) {
              return false;
            }
          }
          if (widget.toDate != null && begin != null) {
            final beginDate = DateTime(begin.year, begin.month, begin.day);
            final toDate = DateTime(widget.toDate!.year, widget.toDate!.month, widget.toDate!.day);
            if (beginDate.isAfter(toDate)) {
              return false;
            }
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
            // If date range filtering is active, only show the first group
            if ((widget.fromDate != null || widget.toDate != null) && groupIdx > 0) {
              return const SizedBox.shrink();
            }
            
            final groupKey = sortedKeys[groupIdx];
            
            // When date range filtering is active, show ALL sessions from the original entries list
            final List<_HistoryEntry> entriesToShow;
            if (widget.fromDate != null || widget.toDate != null) {
              // Get all entries directly from the original entries list (already filtered by date range)
              entriesToShow = entries;
            } else {
              // Normal behavior: show only this group's entries
              entriesToShow = grouped[groupKey]!;
            }
            
            final groupTotal = entriesToShow.fold<Duration>(
                Duration.zero, (accDuration, e) => accDuration + e.duration);
            final groupExpense = entriesToShow.fold<double>(0.0, (accAmount, e) {
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
                              (widget.fromDate != null || widget.toDate != null) 
                                  ? 'Selected Date Range' 
                                  : groupKey,
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
                  ...entriesToShow.map((entry) {
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
                                  icon: Icon(Icons.edit,
                                      color: Theme.of(context).extension<AppColors>()!.primaryBlue, size: 20),
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
                        List<Widget> totalWidgets = [];
                        
                        // If date range filtering is active, calculate totals for entire range
                        if (widget.fromDate != null || widget.toDate != null) {
                          // Only show combined totals for the first group when date range filtering is active
                          if (groupIdx == 0) {
                            // Calculate combined totals for all groups in the selected date range
                            final allEntries = grouped.values.expand((entries) => entries).toList();
                            final combinedTotal = allEntries.fold<Duration>(
                                Duration.zero, (accDuration, e) => accDuration + e.duration);
                            final combinedExpense = allEntries.fold<double>(0.0, (accAmount, e) {
                              if (e.expense.isNaN) {
                                return accAmount;
                              }
                              return accAmount + e.expense;
                            });
                            
                            totalWidgets = [
                              Text(
                                '${AppLocalizations.of(context)!.totalTime}: ${_formatDuration(combinedTotal)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.totalExpenses}: ${expenseFormat.format(combinedExpense)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ];
                          } else {
                            // For other groups when date range filtering is active, don't show totals
                            return const SizedBox.shrink();
                          }
                        } else {
                          // No date range filtering - show per-group totals
                          totalWidgets = [
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
                        }

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
                                  // Create a fresh copy of totalWidgets to avoid modifying the original
                                  final List<Widget> overtimeWidgets = List.from(totalWidgets);
                                  
                                  if (overtimeSnapshot.hasData &&
                                      overtimeSnapshot.data != null) {
                                    final overtimeData = overtimeSnapshot.data!;
                                    final overtimeMinutes =
                                        overtimeData['current'] as int? ?? 0;
                                    // Show overtime value
                                    final isOvertime = overtimeMinutes > 0;
                                    final color =
                                        isOvertime ? Colors.green : Colors.red;

                                    overtimeWidgets.add(
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
                                    children: overtimeWidgets,
                                  );
                                },
                              );
                            } else {
                              // For other groups when date range filtering is active, don't show anything
                              return const SizedBox.shrink();
                            }
                          } else {
                            // Calculate overtime based on grouping type (only when no date range filtering)
                            // Use the same OvertimeCalculationService for consistency
                            Future<Map<String, dynamic>?> overtimeFuture;

                            switch (widget.groupType) {
                              case GroupType.day:
                                // For single day, calculate overtime for that specific day
                                final dayDate = DateFormat('dd/MM/yyyy').parse(groupKey);
                                overtimeFuture = OvertimeCalculationService.calculateOvertimeFromLogs(
                                  widget.companyId,
                                  widget.userId,
                                  fromDate: DateTime(dayDate.year, dayDate.month, dayDate.day),
                                  toDate: DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59),
                                );
                                break;
                              case GroupType.week:
                                // For week, calculate overtime for the full week
                                final weekParts = groupKey.split(', ');
                                final year = int.parse(weekParts[1]);
                                final weekNumber = int.parse(weekParts[0].split(' ')[1]);
                                final jan4 = DateTime(year, 1, 4);
                                final startOfYear = jan4.subtract(Duration(days: jan4.weekday - 1));
                                final weekStart = startOfYear.add(Duration(days: (weekNumber - 1) * 7));
                                final weekEnd = weekStart.add(const Duration(days: 6));
                                overtimeFuture = OvertimeCalculationService.calculateOvertimeFromLogs(
                                  widget.companyId,
                                  widget.userId,
                                  fromDate: weekStart,
                                  toDate: weekEnd,
                                );
                                break;
                              case GroupType.month:
                                // For month, calculate overtime for the full month
                                final monthDate = DateFormat('MMMM yyyy').parse(groupKey);
                                final monthStart = DateTime(monthDate.year, monthDate.month, 1);
                                final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0); // Last day of current month
                                overtimeFuture = OvertimeCalculationService.calculateOvertimeFromLogs(
                                  widget.companyId,
                                  widget.userId,
                                  fromDate: monthStart,
                                  toDate: monthEnd,
                                );
                                break;
                              case GroupType.year:
                                // For year, calculate overtime for the full year
                                final year = int.parse(groupKey);
                                final yearStart = DateTime(year, 1, 1);
                                final yearEnd = DateTime(year + 1, 1, 1);
                                overtimeFuture = OvertimeCalculationService.calculateOvertimeFromLogs(
                                  widget.companyId,
                                  widget.userId,
                                  fromDate: yearStart,
                                  toDate: yearEnd,
                                );
                                break;
                            }

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: overtimeFuture,
                              builder: (context, overtimeSnapshot) {
                                // Create a fresh copy of totalWidgets to avoid modifying the original
                                final List<Widget> groupOvertimeWidgets = List.from(totalWidgets);
                                
                                if (overtimeSnapshot.hasData &&
                                    overtimeSnapshot.data != null) {
                                  final overtimeData = overtimeSnapshot.data!;
                                  // Use 'current' field for consistency with other views
                                  final overtimeMinutes = overtimeData['current'] as int? ?? 0;
                                  // Show overtime value
                                  final isOvertime = overtimeMinutes > 0;
                                  final color =
                                      isOvertime ? Colors.green : Colors.red;

                                  groupOvertimeWidgets.add(
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
                                  children: groupOvertimeWidgets,
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
