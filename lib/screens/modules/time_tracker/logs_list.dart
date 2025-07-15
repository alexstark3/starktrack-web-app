import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';

typedef ProjectInfo = Map<String, String>; // {'id': '...', 'name': '...'}

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
  final List<ProjectInfo> projects;
  final bool showBreakCards;   // NEW

  const LogsList({
    Key? key,
    required this.companyId,
    required this.userId,
    required this.selectedDay,
    required this.projects,
    this.showBreakCards = true,  // default for backward compat
  }) : super(key: key);

  String _projectNameFromId(String id) {
    if (id.isEmpty) return '';
    final p = projects.where((proj) => proj['id'] == id).toList();
    return p.isNotEmpty ? (p.first['name'] ?? '') : id;
  }

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
            final String projectId = (log['projectId'] ?? log['project'] ?? '') as String;
            final String projectName = _projectNameFromId(projectId);
            final List<String> projectLines = [projectName];

            // --- INSERT BREAK CARD IF THERE'S A GAP and break cards should be shown ---
            if (showBreakCards && i > 0) {
              final prev   = docs[i - 1].data() as Map<String, dynamic>;
              final prevEnd= (prev['end'] as Timestamp?)?.toDate();
              if (prevEnd != null && begin != null && prevEnd.isBefore(begin)) {
                final breakDuration = begin.difference(prevEnd);
                final breakStr = _formatBreak(prevEnd, begin, breakDuration);

                rows.add(
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[200],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
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
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    child: _LogEditRow(
                      logId      : logId,
                      begin      : begin,
                      end        : end,
                      projectId  : projectId,
                      projectName: projectName,
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
                      onSave     : (newStart, newEnd, newNote, newProjId, newExpenses) async {
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
                            'projectId': newProjId,
                            'project': _projectNameFromId(newProjId),
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

  String _formatBreak(DateTime from, DateTime to, Duration d) {
    final startStr = DateFormat.Hm().format(from);
    final endStr   = DateFormat.Hm().format(to);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return 'Break: $startStr - $endStr = $h:$m' + 'h';
  }

  Widget _shellCard(ThemeData theme, Widget child) => Card(
        color : theme.cardColor,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child : child,
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
  final Future<void> Function(String, String, String, String, Map<String, dynamic>) onSave;
  final List<ProjectInfo> projects;
  final String? perDiemLogId;

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
  }) : super(key: key);

  @override
  State<_LogEditRow> createState() => _LogEditRowState();
}

class _LogEditRowState extends State<_LogEditRow> {
  bool editing = false;
  late TextEditingController startCtrl, endCtrl, noteCtrl;
  bool _saving = false;
  String? selectedProjectId;
  late Map<String, dynamic> expenses;

  @override
  void initState() {
    super.initState();
    startCtrl = TextEditingController(
      text: widget.begin != null ? DateFormat.Hm().format(widget.begin!) : '');
    endCtrl = TextEditingController(
      text: widget.end != null ? DateFormat.Hm().format(widget.end!) : '');
    noteCtrl    = TextEditingController(text: widget.note);
    selectedProjectId = widget.projectId.isNotEmpty
        ? widget.projectId
        : (widget.projects.isNotEmpty ? widget.projects.first['id'] : null);
    expenses = Map<String, dynamic>.from(widget.expensesMap);
  }

  @override
  void dispose() {
    startCtrl.dispose();
    endCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _showEditExpensesPopup() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(expenses);

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
    final style = TextStyle(color: widget.textColor, fontSize: 16);

    if (!editing) {
      // Read-only: all in lines
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText('Work', '${startCtrl.text.isNotEmpty ? startCtrl.text : '--'} - ${endCtrl.text.isNotEmpty ? endCtrl.text : '--'} = ${widget.duration.inMinutes == 0
            ? '00:00h'
            : '${widget.duration.inHours.toString().padLeft(2, '0')}:${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h'}'),
          _infoText('Project', widget.projectName),
          Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('Expenses:', style: style),
    const SizedBox(width: 8),
    if (widget.expenseLines.isEmpty)
      Text('-', style: style.copyWith(color: Colors.grey)),
    ...widget.expenseLines.map((line) => Text(line, style: style)),
  ],
),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Note:', style: style),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  noteCtrl.text,
                  style: style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                _iconBtn(Icons.edit, Colors.blue[400]!, () => setState(() => editing = true)),
                const SizedBox(width: 8),
                _iconBtn(Icons.delete, Colors.red[300]!, () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Entry'),
      content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        ElevatedButton(
          child: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
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

    // Edit mode
    final List<String> currExpenseLines = [
      for (var entry in expenses.entries)
        if (entry.key != 'Per diem')
          '${entry.key} ${(entry.value as num).toStringAsFixed(2)} CHF',
      if (expenses.containsKey('Per diem'))
        'Per diem ${(expenses['Per diem'] as num).toStringAsFixed(2)} CHF',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoText('Work', '${startCtrl.text.isNotEmpty ? startCtrl.text : '--'} - ${endCtrl.text.isNotEmpty ? endCtrl.text : '--'} = ${widget.duration.inMinutes == 0
          ? '00:00h'
          : '${widget.duration.inHours.toString().padLeft(2, '0')}:${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h'}'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Project: ', style: style),
            Expanded(child: _projectDropdown(style)),
          ],
        ),
        GestureDetector(
          onTap: _showEditExpensesPopup,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Expenses:', style: style),
              const SizedBox(width: 8),
              if (currExpenseLines.isEmpty)
                Text('Tap to add', style: style.copyWith(color: Colors.grey)),
              ...currExpenseLines.map((line) => Text(line, style: style)),
            ],
          ),
        ),


        const SizedBox(height: 20), //gap between note and exp

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Note:', style: style),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: noteCtrl,
                style: style,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _iconBtn(Icons.save, widget.appColors.green, () async {
                if (_saving) return;
                setState(() => _saving = true);
                await widget.onSave(
                  startCtrl.text,
                  endCtrl.text,
                  noteCtrl.text,
                  selectedProjectId ?? '',
                  expenses,
                );
                setState(() {
                  editing = false;
                  _saving = false;
                });
              }),
              const SizedBox(width: 8),
              _iconBtn(Icons.cancel, widget.appColors.orange,
                  () => setState(() => editing = false)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete, Colors.red[300]!, () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Entry'),
      content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        ElevatedButton(
          child: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
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
        child: Text('$label: $value', style: TextStyle(color: widget.textColor, fontSize: 16)),
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
