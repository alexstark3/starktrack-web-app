import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/l10n/app_localizations.dart';

typedef ProjectInfo = Map<String, String>;

const double kWidthLabel = 50;
const double kWidthSpacer = 5;
const double kWidthTime = 50;
const double kWidthDash = 5;
const double kWidthEquals = 5;
const double kWidthTotal = 60;
const double kWidthProject = 150;
const double kWidthExpense = 170;
const double kWidthIcon = 38;

class LogsList extends StatefulWidget {
  final String companyId;
  final String userId;
  final DateTime selectedDay;
  final List<ProjectInfo> projects;
  final bool showBreakCards;

  const LogsList({
    Key? key,
    required this.companyId,
    required this.userId,
    required this.selectedDay,
    required this.projects,
    this.showBreakCards = true,
  }) : super(key: key);

  @override
  State<LogsList> createState() => _LogsListState();
}

class _LogsListState extends State<LogsList> {
  final Map<String, bool> _editingStates = {};
  final Map<String, Map<String, dynamic>> _pendingExpenses = {};
  final Map<String, String> _pendingNotes = {};

  void setEditingState(String logId, bool editing) {
    setState(() {
      _editingStates[logId] = editing;
    });
  }

  bool isEditing(String logId) => _editingStates[logId] ?? false;

  void updateExpenses(String logId, Map<String, dynamic> expenses) {
    setState(() {
      _pendingExpenses[logId] = expenses;
    });
  }

  void clearPendingExpenses(String logId) {
    setState(() {
      _pendingExpenses.remove(logId);
    });
  }

  Map<String, dynamic> getExpenses(
      String logId, Map<String, dynamic> originalExpenses) {
    return _pendingExpenses[logId] ?? originalExpenses;
  }

  void updateNote(String logId, String note) {
    setState(() {
      _pendingNotes[logId] = note;
    });
  }

  void clearPendingNote(String logId) {
    setState(() {
      _pendingNotes.remove(logId);
    });
  }

  String getNote(String logId, String originalNote) {
    return _pendingNotes[logId] ?? originalNote;
  }

  String _projectNameFromId(String id) {
    if (id.isEmpty) return '';
    final p = widget.projects.where((proj) => proj['id'] == id).toList();
    return p.isNotEmpty ? (p.first['name'] ?? '') : id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final textColor = appColors.textColor;
    final borderColor = theme.dividerColor.withValues(alpha: 0.2);
    final isDark = theme.brightness == Brightness.dark;

    final sessionDate = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final logsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('all_logs')
        .where('sessionDate', isEqualTo: sessionDate)
        .orderBy('begin');

    return StreamBuilder<QuerySnapshot>(
      stream: logsRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shellCard(
            theme,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _shellCard(
            theme,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(child: Text(l10n.noLogsForThisDay)),
            ),
          );
        }

        final docs = snap.data!.docs;
        final rows = <Widget>[];

        String? perDiemLogId;
        for (final doc in docs) {
          final log = doc.data() as Map<String, dynamic>;
          final expenses = Map<String, dynamic>.from(log['expenses'] ?? {});
          if (expenses.containsKey('Per diem')) {
            perDiemLogId = doc.id;
            break;
          }
        }

        for (int i = 0; i < docs.length; i++) {
          final doc = docs[i];
          final log = doc.data() as Map<String, dynamic>;
          final logId = doc.id;

          final begin = (log['begin'] as Timestamp?)?.toDate();
          final end = (log['end'] as Timestamp?)?.toDate();

          final Map<String, dynamic> expensesMap =
              Map<String, dynamic>.from(log['expenses'] ?? {});
          final List<String> expenseLines = [];
          for (var entry in expensesMap.entries) {
            if (entry.key == 'Per diem') continue;
            expenseLines.add(
                '${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF');
          }
          if (expensesMap.containsKey('Per diem')) {
            final value = expensesMap['Per diem'];
            expenseLines.add(
                '${l10n.perDiem} ${(value as num).toStringAsFixed(2)} CHF');
          }

          final String noteText = log['note'] ?? '';
          final String projectId =
              (log['projectId'] ?? log['project'] ?? '') as String;
          final String projectName = _projectNameFromId(projectId);
          final List<String> projectLines = [projectName];

          if (widget.showBreakCards && i > 0) {
            final prev = docs[i - 1].data() as Map<String, dynamic>;
            final prevEnd = (prev['end'] as Timestamp?)?.toDate();
            if (prevEnd != null && begin != null && prevEnd.isBefore(begin)) {
              final breakDuration = begin.difference(prevEnd);
              final breakStr = _formatBreak(prevEnd, begin, breakDuration);

              rows.add(
                Card(
                  key: ValueKey('break_$i'),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      child: Text(
                        breakStr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          rows.add(
            Container(
              key: ValueKey(logId),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark
                    ? appColors.cardColorDark
                    : appColors.backgroundLight,
                border: isDark
                    ? Border.all(color: const Color(0xFF404040), width: 1)
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  child: _LogEditRow(
                    key: ValueKey('row_$logId'),
                    logId: logId,
                    begin: begin,
                    end: end,
                    projectId: projectId,
                    projectName: projectName,
                    projectLines: projectLines,
                    expenseLines: expenseLines,
                    expensesMap: expensesMap,
                    note: noteText,
                    appColors: appColors,
                    borderColor: borderColor,
                    textColor: textColor,
                    duration: (begin != null && end != null)
                        ? end.difference(begin)
                        : Duration.zero,
                    isApproved: (log['approved'] ?? false) == true,
                    isRejected: (log['rejected'] ?? false) == true,
                    isApprovedAfterEdit:
                        (log['approvedAfterEdit'] ?? false) == true,
                    onDelete: () => doc.reference.delete(),
                    onSave: (newStart, newEnd, newNote, newProjId,
                        newExpenses) async {
                      try {
                        final ns = DateFormat.Hm().parse(newStart);
                        final ne = DateFormat.Hm().parse(newEnd);
                        final d = widget.selectedDay;
                        final nb = DateTime(
                            d.year, d.month, d.day, ns.hour, ns.minute);
                        final nn = DateTime(
                            d.year, d.month, d.day, ne.hour, ne.minute);
                        if (!nn.isAfter(nb)) throw Exception('Invalid time');
                        await doc.reference.update({
                          'begin': nb,
                          'end': nn,
                          'duration_minutes': nn.difference(nb).inMinutes,
                          'note': newNote,
                          'projectId': newProjId,
                          'project': _projectNameFromId(newProjId),
                          'expenses': newExpenses,
                        });
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err.toString())));
                      }
                    },
                    projects: widget.projects,
                    perDiemLogId: perDiemLogId,
                    isEditing: isEditing(logId),
                    setEditingState: setEditingState,
                    updateExpenses: updateExpenses,
                    getExpenses: getExpenses,
                    clearPendingExpenses: clearPendingExpenses,
                    updateNote: updateNote,
                    getNote: getNote,
                    clearPendingNote: clearPendingNote,
                  ),
                ),
              ),
            ),
          );
        }

        return _shellCard(
          theme,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Wrap(
              runSpacing: 4,
              spacing: 0,
              children: rows,
            ),
          ),
        );
      },
    );
  }

  String _formatBreak(DateTime from, DateTime to, Duration d) {
    final startStr = DateFormat.Hm().format(from);
    final endStr = DateFormat.Hm().format(to);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${AppLocalizations.of(context)?.breaks ?? 'Breaks'}: $startStr - $endStr = $h:$m' +
        'h';
  }

  Widget _shellCard(ThemeData theme, Widget child) => Card(
        color: theme.cardColor,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: child,
      );
}

class _LogEditRow extends StatefulWidget {
  final String logId;
  final DateTime? begin;
  final DateTime? end;
  final String projectId;
  final String projectName;
  final List<String> projectLines;
  final List<String> expenseLines;
  final Map<String, dynamic> expensesMap;
  final String note;
  final AppColors appColors;
  final Color borderColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDelete;
  final Future<void> Function(
      String, String, String, String, Map<String, dynamic>) onSave;
  final List<ProjectInfo> projects;
  final String? perDiemLogId;
  final bool isEditing;
  final Function(String, bool) setEditingState;
  final Function(String, Map<String, dynamic>) updateExpenses;
  final Function(String, Map<String, dynamic>) getExpenses;
  final Function(String) clearPendingExpenses;
  final Function(String, String) updateNote;
  final Function(String, String) getNote;
  final Function(String) clearPendingNote;
  final bool isApproved;
  final bool isRejected;
  final bool isApprovedAfterEdit;

  const _LogEditRow({
    Key? key,
    required this.logId,
    required this.begin,
    required this.end,
    required this.projectId,
    required this.projectName,
    required this.projectLines,
    required this.expenseLines,
    required this.expensesMap,
    required this.note,
    required this.appColors,
    required this.borderColor,
    required this.textColor,
    required this.duration,
    required this.onDelete,
    required this.onSave,
    required this.projects,
    required this.perDiemLogId,
    required this.isEditing,
    required this.setEditingState,
    required this.updateExpenses,
    required this.getExpenses,
    required this.clearPendingExpenses,
    required this.updateNote,
    required this.getNote,
    required this.clearPendingNote,
    required this.isApproved,
    required this.isRejected,
    required this.isApprovedAfterEdit,
  }) : super(key: key);

  @override
  State<_LogEditRow> createState() => _LogEditRowState();
}

class _LogEditRowState extends State<_LogEditRow>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _dialogOpen = false;
  bool _expenseDialogOpen = false;
  late TextEditingController startCtrl, endCtrl;
  final FocusNode _noteFocus = FocusNode();
  bool _saving = false;
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    startCtrl = TextEditingController(
        text:
            widget.begin != null ? DateFormat.Hm().format(widget.begin!) : '');
    endCtrl = TextEditingController(
        text: widget.end != null ? DateFormat.Hm().format(widget.end!) : '');

    final projectListIds = widget.projects.map((p) => p['id']).toList();
    if (projectListIds.contains(widget.projectId)) {
      selectedProjectId = widget.projectId;
    } else if (widget.projects.isNotEmpty) {
      selectedProjectId = widget.projects.first['id'];
    } else {
      selectedProjectId = null;
    }
  }

  @override
  void didUpdateWidget(_LogEditRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Expenses are now managed at parent level, no need to update here
  }

  @override
  void dispose() {
    startCtrl.dispose();
    endCtrl.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ---- Note Popup (WORKS FOR ALL DEVICES!) ----
  Future<void> _showNotePopup() async {
    setState(() => _dialogOpen = true);

    final currentNote = widget.getNote(widget.logId, widget.note);
    final ctrl = TextEditingController(text: currentNote);

    await showDialog<String>(
      context: context,
      useRootNavigator:
          false, // <-- Use local navigator for mobile compatibility
      builder: (ctx) => AlertDialog(
        title: const Text('Note'),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.8,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your note here...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF969696)
                    : const Color(0xFF6A6A6A),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF404040)
                      : const Color(0xFFD0D0D0),
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D2D30)
                  : const Color(0xFFF8F8F8),
            ),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCCCCCC)
                  : Colors.black87,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final newNote = ctrl.text.trim();
                // Update note at parent level
                widget.updateNote(widget.logId, newNote);
                Navigator.of(ctx).pop(newNote);
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (!mounted) return;
    setState(() {
      _dialogOpen = false;
    });
  }

  // ---- Expenses Popup (WORKS FOR ALL DEVICES!) ----
  Future<void> _showEditExpensesPopup() async {
    setState(() {
      _dialogOpen = true;
      _expenseDialogOpen = true;
    });

    final currentExpenses =
        widget.getExpenses(widget.logId, widget.expensesMap);
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses =
        Map<String, dynamic>.from(currentExpenses);

    bool tempPerDiem = tempExpenses.containsKey('Per diem');
    String? errorMsg;

    final dialogAppColors = Theme.of(context).extension<AppColors>()!;
    Color primaryColor = dialogAppColors.primaryBlue;

    final bool perDiemUsedElsewhere =
        widget.perDiemLogId != null && widget.perDiemLogId != widget.logId;
    final bool perDiemAvailableHere =
        widget.perDiemLogId == null || widget.perDiemLogId == widget.logId;

    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // Disable tap-away to close for mobile
      useRootNavigator: false, // Use local navigator for mobile compatibility
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final appColors = Theme.of(context).extension<AppColors>()!;

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
                tempExpenses[name] =
                    double.parse(amountStr.replaceAll(',', '.'));
                nameCtrl.clear();
                amountCtrl.clear();
                errorMsg = null;
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
                      activeColor: primaryColor,
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
                    onChanged:
                        perDiemAvailableHere ? handlePerDiemChange : null,
                    activeColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const Text('Per Diem'),
                  if (perDiemUsedElsewhere)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message:
                            "Per diem already used in another session today",
                        child: Icon(Icons.info_outline,
                            color: Colors.grey, size: 18),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
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
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF969696)
                                    : const Color(0xFF6A6A6A),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : const Color(0xFFD0D0D0),
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? appColors.cardColorDark
                                  : const Color(0xFFF8F8F8),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFCCCCCC)
                                  : Colors.black87,
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                            onSubmitted: (_) =>
                                canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: amountCtrl,
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF969696)
                                    : const Color(0xFF6A6A6A),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : const Color(0xFFD0D0D0),
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? appColors.cardColorDark
                                  : const Color(0xFFF8F8F8),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFCCCCCC)
                                  : Colors.black87,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setStateDialog(() {}),
                            onSubmitted: (_) =>
                                canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: primaryColor,
                              foregroundColor: appColors.whiteTextOnBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: canAddExpense() ? addExpense : null,
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                        child: Text(errorMsg!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel',
                      style: TextStyle(color: primaryColor, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: appColors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    final result = Map<String, dynamic>.from(tempExpenses);

                    // Update expenses at parent level
                    widget.updateExpenses(widget.logId, result);

                    Navigator.pop(context, result);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    // Expenses should already be updated at parent level
    setState(() {
      _dialogOpen = false;
      _expenseDialogOpen = false;
    });
  }

  Widget _projectDropdown(TextStyle s) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.projects.any((proj) => proj['id'] == selectedProjectId)
            ? selectedProjectId
            : null,
        items: widget.projects.map((proj) {
          return DropdownMenuItem(
            value: proj['id'],
            child: Text(proj['name'] ?? proj['id']!, style: s),
          );
        }).toList(),
        hint: const Text('Select project'),
        onChanged: (value) {
          setState(() {
            selectedProjectId = value;
          });
        },
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Prevent edit state loss when dialogs are open
    if ((_dialogOpen || _expenseDialogOpen) && !widget.isEditing) {
      return const SizedBox.shrink();
    }
    final style = TextStyle(color: widget.textColor, fontSize: 16);

    if (!widget.isEditing) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText(l10n.work,
              '${startCtrl.text.isNotEmpty ? startCtrl.text : '--'} - ${endCtrl.text.isNotEmpty ? endCtrl.text : '--'} = ${widget.duration.inMinutes == 0 ? '00:00h' : '${widget.duration.inHours.toString().padLeft(2, '0')}:${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h'}'),
          _infoText(l10n.project, widget.projectName),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.expenses}:', style: style),
              const SizedBox(width: 8),
              if (widget.expenseLines.isEmpty)
                Text('-', style: style.copyWith(color: Colors.grey))
              else
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.expenseLines
                        .map((line) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? widget.appColors.primaryBlue
                                        .withValues(alpha: 0.2)
                                    : widget.appColors.primaryBlue
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: widget.appColors.primaryBlue
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(line,
                                  style: style.copyWith(fontSize: 13)),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.note}:', style: style),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.getNote(widget.logId, widget.note).isNotEmpty
                      ? widget.getNote(widget.logId, widget.note)
                      : l10n.noNote,
                  style: style.copyWith(
                    fontSize: 14,
                    color: widget.getNote(widget.logId, widget.note).isNotEmpty
                        ? widget.textColor
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                widget.isApprovedAfterEdit
                    ? _iconBtn(Icons.verified, Colors.orange, () {}, 'Edited')
                    : widget.isApproved
                        ? _iconBtn(
                            Icons.verified, Colors.green, () {}, 'Approved')
                        : widget.isRejected
                            ? _iconBtn(
                                Icons.cancel, Colors.red, () {}, 'Rejected')
                            : _iconBtn(
                                Icons.edit,
                                Colors.blue[400]!,
                                () =>
                                    widget.setEditingState(widget.logId, true)),
                const SizedBox(width: 8),
                widget.isApprovedAfterEdit
                    ? _iconBtn(Icons.verified, Colors.orange, () {}, 'Edited')
                    : widget.isApproved
                        ? _iconBtn(
                            Icons.verified, Colors.green, () {}, 'Approved')
                        : widget.isRejected
                            ? _iconBtn(
                                Icons.cancel, Colors.red, () {}, 'Rejected')
                            : _iconBtn(Icons.delete, Colors.red[300]!,
                                () async {
                                final l10n = AppLocalizations.of(context)!;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.deleteEntry),
                                    content: Text(l10n.deleteEntryMessage),
                                    actions: [
                                      TextButton(
                                        child: Text(l10n.cancel),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                      ),
                                      ElevatedButton(
                                        child: Text(l10n.delete),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor:
                                              widget.appColors.whiteTextOnBlue,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  widget.onDelete();
                                }
                              }),
              ],
            ),
          ),
        ],
      );
    }

    final expensesToDisplay =
        widget.getExpenses(widget.logId, widget.expensesMap);
    final List<String> currExpenseLines = [
      for (var entry in expensesToDisplay.entries)
        if (entry.key != 'Per diem')
          '${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF',
      if (expensesToDisplay.containsKey('Per diem'))
        'Per diem ${(expensesToDisplay['Per diem'] as num).toStringAsFixed(2)} CHF',
    ];

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoText(l10n.work,
            '${startCtrl.text.isNotEmpty ? startCtrl.text : '--'} - ${endCtrl.text.isNotEmpty ? endCtrl.text : '--'} = ${widget.duration.inMinutes == 0 ? '00:00h' : '${widget.duration.inHours.toString().padLeft(2, '0')}:${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h'}'),
        if (widget.isApprovedAfterEdit ||
            widget.isApproved ||
            widget.isRejected)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  widget.isApprovedAfterEdit
                      ? Icons.verified
                      : widget.isApproved
                          ? Icons.verified
                          : Icons.cancel,
                  color: widget.isApprovedAfterEdit
                      ? Colors.orange
                      : widget.isApproved
                          ? Colors.green
                          : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isApprovedAfterEdit
                      ? l10n.approvedAfterEdit
                      : widget.isApproved
                          ? l10n.approved
                          : l10n.rejected,
                  style: TextStyle(
                    color: widget.isApprovedAfterEdit
                        ? Colors.orange
                        : widget.isApproved
                            ? Colors.green
                            : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${l10n.project}: ', style: style),
            Expanded(child: _projectDropdown(style)),
          ],
        ),
        GestureDetector(
          onTap: _showEditExpensesPopup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.expenses}:', style: style),
                  const SizedBox(width: 8),
                  if (currExpenseLines.isEmpty)
                    Text(l10n.tapToAdd,
                        style: style.copyWith(color: Colors.grey))
                  else
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: currExpenseLines
                            .map((line) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? widget.appColors.primaryBlue
                                            .withValues(alpha: 0.2)
                                        : widget.appColors.primaryBlue
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: widget.appColors.primaryBlue
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(line,
                                      style: style.copyWith(fontSize: 13)),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showNotePopup,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${l10n.note}:', style: style),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: widget.borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? widget.appColors.cardColorDark
                        : const Color(0xFFF0F0F0),
                  ),
                  child: Builder(
                    builder: (context) {
                      final displayNote =
                          widget.getNote(widget.logId, widget.note);
                      return Text(
                        displayNote.isNotEmpty
                            ? displayNote
                            : l10n.tapToAddNote,
                        style: style.copyWith(
                            color: displayNote.isNotEmpty
                                ? widget.textColor
                                : Colors.grey,
                            fontSize: 14),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _iconBtn(Icons.save, widget.appColors.green, () async {
                if (_saving) return;
                setState(() => _saving = true);
                try {
                  final expensesToSave =
                      widget.getExpenses(widget.logId, widget.expensesMap);
                  final noteToSave = widget.getNote(widget.logId, widget.note);
                  await widget.onSave(
                    startCtrl.text,
                    endCtrl.text,
                    noteToSave,
                    selectedProjectId ?? '',
                    expensesToSave,
                  );
                  widget.setEditingState(widget.logId, false);
                  // Clear pending data after successful save so database values are used
                  widget.clearPendingExpenses(widget.logId);
                  widget.clearPendingNote(widget.logId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Changes saved successfully!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Save failed: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _saving = false);
                  }
                }
              }),
              const SizedBox(width: 8),
              _iconBtn(Icons.cancel, widget.appColors.orange,
                  () => widget.setEditingState(widget.logId, false)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete, Colors.red[300]!, () async {
                final l10n = AppLocalizations.of(context)!;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.deleteEntry),
                    content: Text(l10n.deleteEntryMessage),
                    actions: [
                      TextButton(
                        child: Text(l10n.cancel),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      ElevatedButton(
                        child: Text(l10n.delete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: widget.appColors.whiteTextOnBlue,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  widget.onDelete();
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoText(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text('$label: $value',
            style: TextStyle(color: widget.textColor, fontSize: 16)),
      );

  Widget _iconBtn(IconData i, Color c, VoidCallback? onTap,
          [String? tooltip]) =>
      SizedBox(
        width: kWidthIcon,
        child: IconButton(
          icon: Icon(i, color: c),
          tooltip: tooltip ??
              (i == Icons.save
                  ? 'Save'
                  : i == Icons.cancel
                      ? 'Cancel'
                      : i == Icons.edit
                          ? 'Edit'
                          : 'Delete'),
          onPressed: onTap,
        ),
      );
}
