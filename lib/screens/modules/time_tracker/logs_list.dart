// lib/screens/modules/time_tracker/logs_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';

typedef ProjectInfo = Map<String, String>; // {'id': '…', 'name': '…'}

/* ─────────── column widths (unchanged) ─────────── */
const double kWidthLabel   = 50;
const double kWidthSpacer  = 5;
const double kWidthTime    = 50;
const double kWidthDash    = 5;
const double kWidthEquals  = 5;
const double kWidthTotal   = 60;
const double kWidthProject = 150;
const double kWidthExpense = 170;
const double kWidthIcon    = 38;
/* ──────────────────────────────────────────────── */

class LogsList extends StatelessWidget {
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

          /* Which session (if any) already has Per-Diem so we can disable it elsewhere */
          String? perDiemLogId;
          for (final doc in docs) {
            final log = doc.data() as Map<String, dynamic>;
            final exp = Map<String, dynamic>.from(log['expenses'] ?? {});
            if (exp.containsKey('Per diem')) {
              perDiemLogId = doc.id;
              break;
            }
          }

          for (int i = 0; i < docs.length; i++) {
            final doc   = docs[i];
            final log   = doc.data() as Map<String, dynamic>;
            final logId = doc.id;

            final begin = (log['begin'] as Timestamp?)?.toDate();
            final end   = (log['end']   as Timestamp?)?.toDate();

            final Map<String, dynamic> expensesMap =
                Map<String, dynamic>.from(log['expenses'] ?? {});
            final List<String> expenseLines = [
              for (var e in expensesMap.entries)
                if (e.key != 'Per diem')
                  '${e.key} ${(e.value as num).toStringAsFixed(2)} CHF',
              if (expensesMap.containsKey('Per diem'))
                'Per diem ${(expensesMap['Per diem'] as num).toStringAsFixed(2)} CHF',
            ];

            final String noteText  = log['note'] ?? '';
            final String projectId = (log['projectId'] ?? log['project'] ?? '') as String;
            final String projectName = _projectNameFromId(projectId);

            /* Break card */
            if (showBreakCards && i > 0) {
              final prev    = docs[i - 1].data() as Map<String, dynamic>;
              final prevEnd = (prev['end'] as Timestamp?)?.toDate();
              if (prevEnd != null && begin != null && prevEnd.isBefore(begin)) {
                final d = begin.difference(prevEnd);
                rows.add(
                  Card(
                    key: ValueKey('break_$i'),
                    margin : const EdgeInsets.symmetric(vertical: 4),
                    color  : Colors.grey[200],
                    shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    child  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                      child  : Text(
                        'Break: ${DateFormat.Hm().format(prevEnd)} - ${DateFormat.Hm().format(begin)} = '
                        '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}h',
                        style: const TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                );
              }
            }

            /* Work-session card */
            rows.add(
              Card(
                key      : ValueKey(logId),
                margin   : const EdgeInsets.symmetric(vertical: 4),
                elevation: 2,
                shape    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child    : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  child  : _LogEditRow(
                    key            : ValueKey('row_$logId'),
                    logId          : logId,
                    begin          : begin,
                    end            : end,
                    projectId      : projectId,
                    projectName    : projectName,
                    expenseLines   : expenseLines,
                    expensesMap    : expensesMap,
                    note           : noteText,
                    appColors      : appColors,
                    borderColor    : borderColor,
                    textColor      : textColor,
                    duration       : (begin != null && end != null)
                                      ? end.difference(begin)
                                      : Duration.zero,
                    onDelete       : () => doc.reference.delete(),
                    onSave         : (s, e, n, p, ex) async {
                      try {
                        final ns = DateFormat.Hm().parse(s);
                        final ne = DateFormat.Hm().parse(e);
                        final d  = selectedDay;
                        final nb = DateTime(d.year, d.month, d.day, ns.hour, ns.minute);
                        final nn = DateTime(d.year, d.month, d.day, ne.hour, ne.minute);
                        if (!nn.isAfter(nb)) throw Exception('Invalid time');
                        await doc.reference.update({
                          'begin'   : nb,
                          'end'     : nn,
                          'duration_minutes': nn.difference(nb).inMinutes,
                          'note'    : n,
                          'projectId': p,
                          'project' : _projectNameFromId(p),
                          'expenses': ex,
                        });
                      } catch (err) {
                        ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err.toString())));
                      }
                    },
                    projects       : projects,
                    perDiemLogId   : perDiemLogId,
                  ),
                ),
              ),
            );
          }

          return _shellCard(
            theme,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Wrap(runSpacing: 4, children: rows),
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
}

/* ─────────────────────────── _LogEditRow ─────────────────────────── */

class _LogEditRow extends StatefulWidget {
  final String logId;
  final DateTime? begin, end;
  final String projectId, projectName;
  final List<String> expenseLines;
  final Map<String, dynamic> expensesMap;
  final String note;
  final AppColors appColors;
  final Color borderColor, textColor;
  final Duration duration;
  final VoidCallback onDelete;
  final Future<void> Function(
      String, String, String, String, Map<String, dynamic>) onSave;
  final List<ProjectInfo> projects;
  final String? perDiemLogId;

  const _LogEditRow({
    Key? key,
    required this.logId,
    required this.begin,
    required this.end,
    required this.projectId,
    required this.projectName,
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

class _LogEditRowState extends State<_LogEditRow>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    endCtrl   = TextEditingController(
        text: widget.end   != null ? DateFormat.Hm().format(widget.end!)   : '');
    noteCtrl  = TextEditingController(text: widget.note);

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

  /* ------------------------------ NOTE POPUP ------------------------------ */
  Future<void> _showNotePopup() async {
    final ctrl = TextEditingController(text: noteCtrl.text);
    final res  = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title  : const Text('Note'),
        content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return;
    if (res != null) setState(() => noteCtrl.text = res.trim());
  }

  /* --------------------------- EXPENSES POPUP ----------------------------- */
  Future<void> _showEditExpensesPopup() async {
    final nameCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();

    Map<String, dynamic> tmp = Map<String, dynamic>.from(expenses);
    bool perDiem = tmp.containsKey('Per diem');
    String? err;

    final bool perDiemUsedElsewhere =
        widget.perDiemLogId != null && widget.perDiemLogId != widget.logId;

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool canAdd() {
            final n = nameCtrl.text.trim();
            final a = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
            return n.isNotEmpty &&
                   a != null && a > 0 &&
                   !tmp.containsKey(n) &&
                   n != 'Per diem';
          }

          void addExpense() {
            if (!canAdd()) return;
            setState(() {
              tmp[nameCtrl.text.trim()] =
                  double.parse(amountCtrl.text.trim().replaceAll(',', '.'));
              nameCtrl.clear();
              amountCtrl.clear();
              err = null;
            });
          }

          final other = tmp.keys.where((k) => k != 'Per diem');

          return AlertDialog(
            shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title : const Text('Expenses'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final k in other)
                    Row(children: [
                      Checkbox(
                          value: true,
                          onChanged: (_) => setState(() => tmp.remove(k))),
                      Text(k),
                      const Spacer(),
                      Text('${(tmp[k] as num).toStringAsFixed(2)} CHF'),
                    ]),
                  Row(children: [
                    Checkbox(
                      value: perDiem,
                      onChanged: perDiemUsedElsewhere
                          ? null
                          : (v) => setState(() {
                                perDiem = v ?? false;
                                if (perDiem) {
                                  tmp['Per diem'] = 16.00;
                                } else {
                                  tmp.remove('Per diem');
                                }
                              }),
                    ),
                    const Text('Per Diem'),
                    if (perDiemUsedElsewhere)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child  : Icon(Icons.info_outline, size: 18)),
                    const Spacer(),
                    const Text('16.00 CHF'),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Name', isDense: true),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => addExpense(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Amount', isDense: true),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => addExpense(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: canAdd() ? addExpense : null,
                      child: const Text('Add'),
                    ),
                  ]),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child  : Text(err!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogCtx).pop(Map<String, dynamic>.from(tmp)),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) setState(() => expenses = result);
  }

  /* ---------------- UI helpers & build ---------------- */
  Widget _dropdown(TextStyle s) => DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.projects.any((p) => p['id'] == selectedProjectId)
              ? selectedProjectId
              : null,
          isExpanded: true,
          items: [
            for (final p in widget.projects)
              DropdownMenuItem(value: p['id'], child: Text(p['name']!, style: s)),
          ],
          hint: const Text('Select project'),
          onChanged: (v) => setState(() => selectedProjectId = v),
        ),
      );

  Widget _info(String l, String v, TextStyle s) =>
      Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('$l: $v', style: s));

  Widget _icon(IconData i, Color c, VoidCallback? f) =>
      SizedBox(width: kWidthIcon, child: IconButton(icon: Icon(i, color: c), onPressed: f));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = TextStyle(color: widget.textColor, fontSize: 16);

    /* READ-ONLY ------------------------------------------------------ */
    if (!editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info(
              'Work',
              '${startCtrl.text} - ${endCtrl.text} = '
              '${widget.duration.inHours.toString().padLeft(2, '0')}:'
              '${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h',
              s),
          _info('Project', widget.projectName, s),
          Row(children: [
            Text('Expenses:', style: s),
            const SizedBox(width: 8),
            if (widget.expenseLines.isEmpty)
              Text('-', style: s.copyWith(color: Colors.grey)),
            ...widget.expenseLines.map((e) => Text(e, style: s)),
          ]),
          Row(children: [
            Text('Note:', style: s),
            const SizedBox(width: 8),
            Expanded(
              child: Text(noteCtrl.text,
                  style: s, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              _icon(Icons.edit, Colors.blue, () => setState(() => editing = true)),
              const SizedBox(width: 8),
              _icon(Icons.delete, Colors.red, widget.onDelete),
            ]),
          ),
        ],
      );
    }

    /* EDIT ----------------------------------------------------------- */
    final expPreview = [
      for (final e in expenses.entries)
        if (e.key != 'Per diem')
          '${e.key} ${(e.value as num).toStringAsFixed(2)} CHF',
      if (expenses.containsKey('Per diem'))
        'Per diem ${(expenses['Per diem'] as num).toStringAsFixed(2)} CHF',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info(
            'Work',
            '${startCtrl.text} - ${endCtrl.text} = '
            '${widget.duration.inHours.toString().padLeft(2, '0')}:'
            '${(widget.duration.inMinutes % 60).toString().padLeft(2, '0')}h',
            s),
        Row(children: [
          Text('Project:', style: s),
          const SizedBox(width: 8),
          Expanded(child: _dropdown(s)),
        ]),
        GestureDetector(
          onTap: _showEditExpensesPopup,
          child: Row(children: [
            Text('Expenses:', style: s),
            const SizedBox(width: 8),
            if (expPreview.isEmpty)
              Text('Tap to add', style: s.copyWith(color: Colors.grey)),
            ...expPreview.map((e) => Text(e, style: s)),
          ]),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showNotePopup,
          child: Row(children: [
            Text('Note:', style: s),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: widget.borderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: Text(
                  noteCtrl.text.isNotEmpty
                      ? noteCtrl.text
                      : 'Tap to add note',
                  style: s.copyWith(
                      color: noteCtrl.text.isNotEmpty
                          ? widget.textColor
                          : Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            _icon(Icons.save, widget.appColors.green, () async {
              if (_saving) return;
              setState(() => _saving = true);
              await widget.onSave(
                startCtrl.text,
                endCtrl.text,
                noteCtrl.text,
                selectedProjectId ?? '',
                expenses,
              );
              if (mounted) setState(() {
                editing = false;
                _saving  = false;
              });
            }),
            const SizedBox(width: 8),
            _icon(Icons.cancel, widget.appColors.orange,
                () => setState(() => editing = false)),
            const SizedBox(width: 8),
            _icon(Icons.delete, Colors.red, widget.onDelete),
          ]),
        ),
      ],
    );
  }
}
