part of team_members_view;

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
    final sessionDate =
        begin != null ? DateFormat('dd/MM/yyyy').format(begin) : '';

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
            .doc(companyId)
            .collection('users')
            .doc(userId)
            .collection('all_logs')
            .where('sessionDate', isEqualTo: sessionDate)
            .get();

        for (var doc in snapshot.docs) {
          if (doc.id != widget.logDoc.id) {
            final docData = doc.data();
            final expenses =
                Map<String, dynamic>.from(docData['expenses'] ?? {});
            if (expenses.containsKey('Per diem')) {
              perDiemUsedElsewhere = true;
              break;
            }
          }
        }
      } catch (_) {}
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
                tempExpenses[name] =
                    double.parse(amountStr.replaceAll(',', '.'));
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
                Row(children: [
                  Checkbox(
                      value: true,
                      onChanged: (checked) => handleExpenseChange(key, checked),
                      activeColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                  Text(key,
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16)),
                  const Spacer(),
                  Text(
                      '${(tempExpenses[key] as num?)?.toStringAsFixed(2) ?? '0.00'} CHF',
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16)),
                ]),
              Row(children: [
                Checkbox(
                    value: tempPerDiem,
                    onChanged: perDiemAvailable ? handlePerDiemChange : null,
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4))),
                Text('Per Diem',
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                        color: perDiemAvailable
                            ? Colors.black
                            : Colors.grey.shade400)),
                const Spacer(),
                const Text('16.00 CHF',
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 16)),
              ]),
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(AppLocalizations.of(context)!.expensesTitle),
              content: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...expenseWidgets,
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            flex: 2,
                            child: TextField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                    hintText:
                                        AppLocalizations.of(context)!.nameLabel,
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 4)),
                                onChanged: (_) => setStateDialog(() {}),
                                onSubmitted: (_) =>
                                    canAddExpense() ? addExpense() : null)),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 1,
                            child: TextField(
                                controller: amountCtrl,
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .amountLabel,
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 4)),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setStateDialog(() {}),
                                onSubmitted: (_) =>
                                    canAddExpense() ? addExpense() : null)),
                        const SizedBox(width: 10),
                        ElevatedButton(
                            onPressed: canAddExpense() ? addExpense : null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: colors.whiteTextOnBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8)),
                            child: Text(AppLocalizations.of(context)!.addLabel,
                                style: const TextStyle(fontSize: 14))),
                      ]),
                    ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancelLabel,
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 16))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: colors.whiteTextOnBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 8),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () => Navigator.pop(context, tempExpenses),
                    child: Text(AppLocalizations.of(context)!.saveLabel)),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? colors.cardColorDark : colors.backgroundLight,
      title: Text(AppLocalizations.of(context)!.editTimeLog,
          style: TextStyle(color: colors.textColor)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _startCtrl,
              decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.start} ${AppLocalizations.of(context)!.time} (HH:mm)'),
              keyboardType: TextInputType.datetime),
          TextField(
              controller: _endCtrl,
              decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.end} ${AppLocalizations.of(context)!.time} (HH:mm)'),
              keyboardType: TextInputType.datetime),
          DropdownButtonFormField<String>(
              value: _projectValue,
              isExpanded: true,
              items: widget.projects
                  .map((name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)))
                  .toList(),
              onChanged: (val) => setState(() {
                    _projectValue = val;
                    _projectError = false;
                  }),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.projectLabel)),
          if (_projectError)
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('${AppLocalizations.of(context)!.selectProject}!',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold))),
          TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.noteLabel)),
          const SizedBox(height: 12),
          GestureDetector(
              onTap: _showExpensePopup,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${AppLocalizations.of(context)!.expenses}:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          if (_expenses.isEmpty)
                            Text(AppLocalizations.of(context)!.tapToAdd,
                                style: const TextStyle(color: Colors.grey))
                          else
                            Expanded(
                                child:
                                    Wrap(spacing: 8, runSpacing: 4, children: [
                              for (var entry in _expenses.entries)
                                if (entry.key != 'Per diem')
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.blue
                                                  .withValues(alpha: 0.2)
                                              : Colors.blue
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.3))),
                                      child: Text(
                                          '${entry.key} ${(entry.value as num?)?.toStringAsFixed(2) ?? '0.00'} CHF',
                                          style:
                                              const TextStyle(fontSize: 13))),
                              if (_expenses.containsKey('Per diem'))
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.blue.withValues(alpha: 0.2)
                                            : Colors.blue
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.blue
                                                .withValues(alpha: 0.3))),
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .perDiemLabel(
                                                (_expenses['Per diem'] as num?)
                                                        ?.toStringAsFixed(2) ??
                                                    '0.00'),
                                        style: const TextStyle(fontSize: 13))),
                            ])),
                        ]),
                  ])),
          const SizedBox(height: 12),
          TextField(
              decoration: const InputDecoration(labelText: 'Approval Note'),
              onChanged: (v) => _approvalNote = v.trim()),
        ]),
      ),
      actions: [
        TextButton(
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: colors.textColor)),
            onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.whiteTextOnBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
            child: Text(
                '${AppLocalizations.of(context)!.save} & ${AppLocalizations.of(context)!.approve}'),
            onPressed: () async {
              DateTime start, end;
              try {
                final baseDay = (widget.logDoc['begin'] as Timestamp).toDate();
                final sParts = _startCtrl.text.split(':');
                final eParts = _endCtrl.text.split(':');
                start = DateTime(baseDay.year, baseDay.month, baseDay.day,
                    int.parse(sParts[0]), int.parse(sParts[1]));
                end = DateTime(baseDay.year, baseDay.month, baseDay.day,
                    int.parse(eParts[0]), int.parse(eParts[1]));
                if (!end.isAfter(start)) {
                  throw AppLocalizations.of(context)!.endBeforeStart;
                }

                // Overlap check (allow touching boundaries)
                final sessionId = DateFormat('yyyy-MM-dd').format(baseDay);
                final dayLogs = await widget.logDoc.reference.parent
                    .where('sessionDate', isEqualTo: sessionId)
                    .get();
                for (final d in dayLogs.docs) {
                  if (d.id == widget.logDoc.id) continue;
                  final data = d.data() as Map<String, dynamic>;
                  final ob = (data['begin'] as Timestamp?)?.toDate();
                  final oe = (data['end'] as Timestamp?)?.toDate();
                  if (ob == null || oe == null) continue;
                  if (start.isBefore(oe) && end.isAfter(ob)) {
                    throw Exception('Time overlaps another entry on this day');
                  }
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Invalid time: overlaps or end before start')));
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
                'projectId': _projectValue,
                'approvalNote': _approvalNote,
                'approved': false,
                'approvedAt': FieldValue.serverTimestamp(),
                'edited': true,
                'approvedAfterEdit': true,
              });
              widget.onSaved();
              Navigator.of(context).pop();
            }),
      ],
    );
  }
}
