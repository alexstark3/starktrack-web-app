import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';

/* ─────────── column widths ─────────── */
const double kWidthLabel    = 50;
const double kWidthSpacer   = 5;
const double kWidthTime     = 50;
const double kWidthDash     = 5;
const double kWidthEquals   = 5;
const double kWidthTotal    = 60;
const double kWidthProject  = 150;
const double kWidthExpense  = 170;
const double kWidthIcon     = 38;
/* ───────────────────────────────────── */

class LogsList extends StatelessWidget {
  final String companyId;
  final String userId;
  final DateTime selectedDay;
  final List<String> projects;

  const LogsList({
    Key? key,
    required this.companyId,
    required this.userId,
    required this.selectedDay,
    required this.projects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final appColors  = theme.extension<AppColors>()!;
    final textColor  = appColors.textColor;
    final borderColor= theme.dividerColor.withOpacity(0.2);
    final isDark     = theme.brightness == Brightness.dark;

    final sessionDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    final logsRef = FirebaseFirestore.instance
        .collection('companies').doc(companyId)
        .collection('users').doc(userId)
        .collection('all_logs')
        .where('sessionDate', isEqualTo: sessionDate)
        .orderBy('begin');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Center(child: Text('No logs for this day.')),
              ),
            );
          }

          final docs = snap.data!.docs;
          final rows = <Widget>[];

          // Track which session (if any) has Per Diem for the day:
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
            final doc  = docs[i];
            final log  = doc.data() as Map<String, dynamic>;
            final logId= doc.id;

            final begin = (log['begin'] as Timestamp?)?.toDate();
            final end   = (log['end']   as Timestamp?)?.toDate();

            final Map<String, dynamic> expensesMap =
                Map<String, dynamic>.from(log['expenses'] ?? {});
            final List<String> expenseLines = [];
            for (var entry in expensesMap.entries) {
              if (entry.key == 'Per diem') continue;
              expenseLines.add('${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF');
            }
            if (expensesMap.containsKey('Per diem')) {
              final value = expensesMap['Per diem'];
              expenseLines.add('Per diem ${(value as num).toStringAsFixed(2)} CHF');
            }

            final String noteText = log['note'] ?? '';
            final String projectRaw = log['project'] ?? '';
            final List<String> projectLines = projectRaw.split('\n');

            if (i > 0) {
              final prev   = docs[i - 1].data() as Map<String, dynamic>;
              final prevEnd= (prev['end'] as Timestamp?)?.toDate();
              if (prevEnd != null && begin != null && prevEnd.isBefore(begin)) {
                rows.add(


                  Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
child: SizedBox(
            width: double.infinity, // <-- makes Card full width
/* Breaks
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: LogRowDisplay(
              label      : 'Break:',
              start      : DateFormat.Hm().format(prevEnd),
              end        : DateFormat.Hm().format(begin),
              total      : _fmtDur(begin.difference(prevEnd)),
              projectLines : const [],
              expenseLines : const [],
              note       : '',
              textColor  : textColor.withOpacity(0.5),
              showIcons  : false,
            ),
          ),*/
        ),
        ),
      );
    }
  }

rows.add(
  Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 2,
    child: SizedBox(

      width: double.infinity, // <-- makes the Card fill horizontal space
      child: Padding(

      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: _LogEditRow(
        logId      : logId,
        begin      : begin,
        end        : end,
        project    : projectRaw,
        projectLines : projectLines,
        expenseLines : expenseLines,
        expensesMap  : expensesMap,
        note       : noteText,
        appColors  : appColors,
        borderColor: borderColor,
        textColor  : textColor,
        duration   : (begin != null && end != null)
            ? end.difference(begin)
            : Duration.zero,
        onDelete   : () => doc.reference.delete(),
        onSave     : (newStart, newEnd, newNote, newProj, newExpenses) async {
          try {
            final ns = DateFormat.Hm().parse(newStart);
            final ne = DateFormat.Hm().parse(newEnd);
            final d  = selectedDay;
            final nb = DateTime(d.year, d.month, d.day, ns.hour, ns.minute);
            final nn = DateTime(d.year, d.month, d.day, ne.hour, ne.minute);
            if (!nn.isAfter(nb)) throw Exception('Invalid time');

            await doc.reference.update({
              'begin' : nb,
              'end'   : nn,
              'duration_minutes': nn.difference(nb).inMinutes,
              'note'  : newNote,
              'project': newProj,
              'expenses': newExpenses,
            });
          } catch (err) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(err.toString())));
          }
        },
        projects: projects,
        perDiemLogId: perDiemLogId,
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
      ),
    );
  }

  Widget _shellCard(ThemeData theme, Widget child) => Card(
        color : theme.cardColor,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child : child,
      );

  String _fmtDur(Duration d) =>
      d.inMinutes == 0
          ? '00:00h'
          : '${d.inHours.toString().padLeft(2, '0')}:'
            '${(d.inMinutes % 60).toString().padLeft(2, '0')}h';
}

/* ───── read-only row widget ───── */

class LogRowDisplay extends StatelessWidget {
  final String label, start, end, total, note;
  final List<String> projectLines, expenseLines;
  final Color textColor;
  final bool showIcons;
  final VoidCallback? onEdit, onDelete;

  const LogRowDisplay({
    Key? key,
    required this.label,
    required this.start,
    required this.end,
    required this.total,
    required this.projectLines,
    required this.expenseLines,
    required this.note,
    required this.textColor,
    this.showIcons = true,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: textColor, fontSize: 16);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
  spacing: 8,    // or whatever spacing you like
  runSpacing: 4, // vertical gap between wraps
  children: [
        SizedBox(width: kWidthLabel,  child: Text(label, style: style)),
        const SizedBox(width: kWidthSpacer),
        SizedBox(width: kWidthTime,   child: Text(start, style: style, textAlign: TextAlign.center)),
        const SizedBox(width: kWidthDash),
        Text('-', style: style),
        const SizedBox(width: kWidthDash),
        SizedBox(width: kWidthTime,   child: Text(end, style: style, textAlign: TextAlign.center)),
        const SizedBox(width: kWidthSpacer),
        Text('=', style: style),
        const SizedBox(width: kWidthSpacer),
        SizedBox(width: kWidthTotal,  child: Text(total, style: style)),
        const SizedBox(width: kWidthSpacer),
        SizedBox(
          width: kWidthProject,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: projectLines.isNotEmpty
                  ? projectLines.map((line) => Text(line, style: style)).toList()
                  : [const SizedBox.shrink()],
            ),
          ),
        ),
        const SizedBox(width: kWidthSpacer),
        SizedBox(
          width: kWidthExpense,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: expenseLines.isNotEmpty
                ? expenseLines.map((line) => Text(line, style: style)).toList()
                : [const SizedBox.shrink()],
          ),
        ),
        const SizedBox(width: kWidthSpacer),
        Text(note, style: style, softWrap: true, overflow: TextOverflow.visible),
        
        if (showIcons) ...[
          SizedBox(
            width: kWidthIcon,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue[400]),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: kWidthIcon,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300]),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ),
        ],
      ],
    );
  }
}

/* ───── editable row widget with correct per diem popup ───── */

class _LogEditRow extends StatefulWidget {
  final String logId;
  final DateTime? begin;
  final DateTime? end;
  final String project;
  final List<String> projectLines;
  final List<String> expenseLines;
  final Map<String, dynamic> expensesMap;
  final String note;
  final AppColors appColors;
  final Color borderColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDelete;
  final Future<void> Function(String, String, String, String, Map<String, dynamic>) onSave;
  final List<String> projects;
  final String? perDiemLogId;

  const _LogEditRow({
    Key? key,
    required this.logId,
    required this.begin,
    required this.end,
    required this.project,
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
  }) : super(key: key);

  @override
  State<_LogEditRow> createState() => _LogEditRowState();
}

class _LogEditRowState extends State<_LogEditRow> {
  bool editing = false;
  late TextEditingController startCtrl,
      endCtrl,
      projectCtrl,
      noteCtrl;
  bool _saving = false;
  String? selectedProject;
  late Map<String, dynamic> expenses;

  @override
  void initState() {
    super.initState();
    startCtrl = TextEditingController(
      text: widget.begin != null ? DateFormat.Hm().format(widget.begin!) : '');
    endCtrl = TextEditingController(
      text: widget.end != null ? DateFormat.Hm().format(widget.end!) : '');
    projectCtrl = TextEditingController(text: widget.project);
    noteCtrl    = TextEditingController(text: widget.note);
    selectedProject = widget.project.isNotEmpty
        ? widget.project
        : (widget.projects.isNotEmpty ? widget.projects.first : null);
    expenses = Map<String, dynamic>.from(widget.expensesMap);
  }

  @override
  void dispose() {
    startCtrl.dispose();
    endCtrl.dispose();
    projectCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  void _formatTime(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return;
    try {
      final clean = t.replaceAll(':', '').padLeft(4, '0');
      final h = int.parse(clean.substring(0, 2));
      final m = int.parse(clean.substring(2, 4));
      c.text = DateFormat.Hm().format(DateTime(2000, 1, 1, h, m));
    } catch (_) {}
  }

  Future<void> _showEditNote() async {
    final ctrl = TextEditingController(text: noteCtrl.text);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(controller: ctrl, minLines: 2, maxLines: 8),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) setState(() => noteCtrl.text = res.trim());
  }

  Future<void> _showProjectPopup() async {
    if (widget.projects.isEmpty) return;
    final res = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Project'),
        children: widget.projects
            .map((p) => SimpleDialogOption(
                  child: Text(p),
                  onPressed: () => Navigator.of(context).pop(p),
                ))
            .toList(),
      ),
    );
    if (res != null) {
      setState(() {
        selectedProject = res;
        projectCtrl.text = res;
      });
    }
  }

  // ===== Edit Expenses Popup with correct Per Diem logic =====
  Future<void> _showEditExpensesPopup() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(expenses);

    // Logic for per diem:
    // If perDiemLogId == null: not used today, enable for all
    // If perDiemLogId == widget.logId: used in this session, allow remove
    // If perDiemLogId != null and not this session: show disabled checkbox

    bool tempPerDiem = tempExpenses.containsKey('Per diem');
    String? errorMsg;

    Color primaryColor = Colors.blue;

    final bool perDiemUsedElsewhere = widget.perDiemLogId != null && widget.perDiemLogId != widget.logId;
    final bool perDiemAvailableHere = widget.perDiemLogId == null || widget.perDiemLogId == widget.logId;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
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

          // Expenses for display (Per diem always last)
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
                  onChanged: perDiemAvailableHere ? handlePerDiemChange : null,
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                const Text('Per Diem'),
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
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: primaryColor,
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
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: primaryColor, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  setState(() {
                    expenses = Map<String, dynamic>.from(tempExpenses);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: widget.textColor, fontSize: 16);

    if (!editing) {
      return LogRowDisplay(
        label   : 'Work:',
        start   : startCtrl.text,
        end     : endCtrl.text,
        total   : widget.duration.inMinutes == 0
            ? '00:00h'
            : '${widget.duration.inHours.toString().padLeft(2, '0')}:'
              '${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h',
        projectLines : widget.projectLines,
        expenseLines : widget.expenseLines,
        note    : noteCtrl.text,
        textColor: widget.textColor,
        onEdit   : () => setState(() => editing = true),
        onDelete : widget.onDelete,
      );
    }

    // Render expenseLines from local editable expenses
    final List<String> currExpenseLines = [
      for (var entry in expenses.entries)
        if (entry.key != 'Per diem')
          '${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF',
      if (expenses.containsKey('Per diem'))
        'Per diem ${(expenses['Per diem'] as num).toStringAsFixed(2)} CHF',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: kWidthLabel, child: Text('Work:', style: style)),
        const SizedBox(width: kWidthSpacer),
        _timeBox(startCtrl, () => _formatTime(startCtrl)),
        const SizedBox(width: kWidthDash),
        Text('-', style: style),
        const SizedBox(width: kWidthDash),
        _timeBox(endCtrl,   () => _formatTime(endCtrl)),
        const SizedBox(width: kWidthSpacer),
        Text('=', style: style),
        const SizedBox(width: kWidthSpacer),
        SizedBox(width: kWidthTotal, child: Text(
          widget.duration.inMinutes == 0
              ? '00:00h'
              : '${widget.duration.inHours.toString().padLeft(2, '0')}:'
                '${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h',
          style: style,
        )),
        const SizedBox(width: kWidthSpacer),
        _projectBox(style),
        const SizedBox(width: kWidthSpacer),
        SizedBox(
          width: kWidthExpense,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...currExpenseLines.map((line) => Text(line, style: style)),
              const SizedBox(height: 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[800],
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _showEditExpensesPopup,
                child: const Text("Edit Expenses"),
              ),
            ],
          ),
        ),
        const SizedBox(width: kWidthSpacer),
        Expanded(
          child: GestureDetector(
            onTap: _showEditNote,
            child: AbsorbPointer(
              child: TextField(
                controller: noteCtrl,
                style: style,
                minLines: 1,
                maxLines: 1,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _iconBtn(Icons.save, widget.appColors.green, () async {
          if (_saving) return;
          setState(() => _saving = true);
          await widget.onSave(
            startCtrl.text,
            endCtrl.text,
            noteCtrl.text,
            selectedProject ?? '',
            expenses,
          );
          setState(() {
            editing = false;
            _saving = false;
          });
        }),
        const SizedBox(width: 4),
        _iconBtn(Icons.cancel, widget.appColors.orange,
            () => setState(() => editing = false)),
        const SizedBox(width: 4),
        _iconBtn(Icons.delete, widget.appColors.red, widget.onDelete),
      ],
    );
  }

  Widget _timeBox(TextEditingController c, VoidCallback onComplete) => SizedBox(
        width: kWidthTime,
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.textColor, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: widget.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          ),
          onEditingComplete: onComplete,
        ),
      );

  Widget _projectBox(TextStyle s) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _showProjectPopup,
        child: Container(
          width: kWidthProject,
          height: 36,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selectedProject ?? 'Project +',
            style: s,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  Widget _iconBtn(IconData i, Color c, VoidCallback? onTap) => SizedBox(
        width: kWidthIcon,
        child: IconButton(
          icon: Icon(i, color: c),
          tooltip: i == Icons.save ? 'Save'
                 : i == Icons.cancel ? 'Cancel'
                 : 'Delete',
          onPressed: onTap,
        ),
      );
}
