import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/l10n/app_localizations.dart';

const double kEntryHeight = 38;
const double kEntryRadius = 9;
const double kFieldSpacing = 8;

class TimeEntryCard extends StatefulWidget {
  final String companyId;
  final String userId;
  final DateTime selectedDay;
  final List<String>
      projects; // List of project names (adjust if structure changes)

  const TimeEntryCard({
    super.key,
    required this.companyId,
    required this.userId,
    required this.selectedDay,
    required this.projects,
  });

  @override
  State<TimeEntryCard> createState() => _TimeEntryCardState();
}

class _TimeEntryCardState extends State<TimeEntryCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final FocusNode _startFocus = FocusNode();
  final FocusNode _endFocus = FocusNode();

  String? _project;
  String? _note;
  bool _isLoading = false;

  // Expenses logic
  Map<String, dynamic> _expenses = {};

  @override
  void initState() {
    super.initState();
    _startFocus
        .addListener(() => _formatOnUnfocus(_startController, _startFocus));
    _endFocus.addListener(() => _formatOnUnfocus(_endController, _endFocus));
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  void _formatOnUnfocus(TextEditingController c, FocusNode n) {
    if (!n.hasFocus) {
      final t = c.text.trim();
      if (t.isEmpty) return;
      try {
        final clean = t.replaceAll(':', '').padLeft(4, '0');
        final h = int.parse(clean.substring(0, 2));
        final m = int.parse(clean.substring(2, 4));
        c.text = DateFormat.Hm().format(DateTime(2000, 1, 1, h, m));
      } catch (_) {}
    }
  }

  Future<void> _showProjectPopup() async {
    if (widget.projects.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<String>(
      context: context,
      useRootNavigator: false, // keep within same navigator tree
      builder: (_) => SimpleDialog(
        title: Text(l10n.selectProject),
        children: widget.projects
            .map((p) => SimpleDialogOption(
                  child: Text(p),
                  onPressed: () => Navigator.pop(context, p),
                ))
            .toList(),
      ),
    );
    if (res != null) setState(() => _project = res);
  }

  Future<void> _showNotePopup() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: _note ?? '');
    final res = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.note),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (res != null) setState(() => _note = res.trim());
  }

  Future<void> _showExpensePopup() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(_expenses);
    bool tempPerDiem = tempExpenses.containsKey('Per diem');
    final appColors = Theme.of(context).extension<AppColors>()!;
    Color primaryColor = appColors.primaryBlue;

    // CHECK for Per Diem in any log for this day!
    final d = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final perDiemQuery = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('all_logs')
        .where('sessionDate', isEqualTo: d)
        .get();

    String? perDiemSessionId;
    for (var doc in perDiemQuery.docs) {
      final data = doc.data();
      final expenses = Map<String, dynamic>.from(data['expenses'] ?? {});
      if (expenses.containsKey('Per diem')) {
        perDiemSessionId = doc.id;
        break;
      }
    }
    // For new session, only allow per diem if not present in any other session yet
    bool canEditPerDiem = (perDiemSessionId == null);

    await showDialog(
      context: context,
      useRootNavigator: false,
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

          // Expenses for display (Per diem last)
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
                  onChanged: canEditPerDiem ? handlePerDiemChange : null,
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Text(
                  l10n.perDiem,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: canEditPerDiem ? Colors.black : Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                Text(l10n.perDiemAmount,
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 16)),
                if (!canEditPerDiem)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: l10n.perDiemAlreadyUsed,
                      child:
                          const Icon(Icons.lock, color: Colors.grey, size: 17),
                    ),
                  ),
              ],
            ),
          ];

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(l10n.expenses),
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
                            hintText: l10n.name,
                            border: const UnderlineInputBorder(),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
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
                            hintText: l10n.amount,
                            border: const UnderlineInputBorder(),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: canAddExpense() ? addExpense : null,
                          child: Text(l10n.add),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel,
                    style: TextStyle(color: primaryColor, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  setState(() {
                    _expenses = Map<String, dynamic>.from(tempExpenses);
                  });
                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _hasOverlap(DateTime begin, DateTime end) async {
    final d = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final q = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('all_logs')
        .where('sessionDate', isEqualTo: d)
        .get();

    for (var doc in q.docs) {
      final data = doc.data();
      final b = (data['begin'] as Timestamp?)?.toDate();
      final e = (data['end'] as Timestamp?)?.toDate();
      if (b == null || e == null) continue;
      if (begin.isBefore(e) && end.isAfter(b)) return true;
    }
    return false;
  }

  // === LOG ID GENERATOR ===
  String _generateLogId(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m$d$h$min$s';
  }

  Future<void> _onAddPressed() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final s = _startController.text.trim();
      final e = _endController.text.trim();
      if (s.isEmpty || e.isEmpty) throw l10n.startAndEndTimesCannotBeEmpty;

      final st = DateFormat.Hm().parse(s);
      final et = DateFormat.Hm().parse(e);
      final d = widget.selectedDay;
      final begin = DateTime(d.year, d.month, d.day, st.hour, st.minute);
      final end = DateTime(d.year, d.month, d.day, et.hour, et.minute);
      if (!end.isAfter(begin)) throw l10n.endTimeMustBeAfterStartTime;
      if (await _hasOverlap(begin, end)) throw l10n.timeOverlap;

      // Check Per Diem again before add!
      final dayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
      final perDiemQuery = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: dayStr)
          .get();
      bool perDiemAlreadyUsed = false;
      for (var doc in perDiemQuery.docs) {
        final data = doc.data();
        final expenses = Map<String, dynamic>.from(data['expenses'] ?? {});
        if (expenses.containsKey('Per diem')) {
          perDiemAlreadyUsed = true;
          break;
        }
      }
      if (_expenses.containsKey('Per diem') && perDiemAlreadyUsed) {
        throw l10n.perDiemAlreadyEntered;
      }

      final mins = end.difference(begin).inMinutes;
      final sessionDate = DateFormat('yyyy-MM-dd').format(d);

      // Get the actual Firestore document ID for the selected project
      String? actualProjectId;
      if (_project != null && _project!.isNotEmpty) {
        final projectQuery = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('projects')
            .where('name', isEqualTo: _project)
            .get();
        if (projectQuery.docs.isNotEmpty) {
          actualProjectId = projectQuery.docs.first.id;
        }
      }

      final logId = _generateLogId(begin);

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .collection('all_logs')
          .doc(logId)
          .set({
        'sessionDate': sessionDate,
        'begin': begin,
        'end': end,
        'duration_minutes': mins,
        'project': _project ?? '',
        'projectId': actualProjectId ?? '',
        'note': _note ?? '',
        'expenses': _expenses,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _startController.clear();
        _endController.clear();
        _project = null;
        _note = null;
        _expenses = {};
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    BoxDecoration fieldDecoration = BoxDecoration(
      color: isDark ? app.cardColorDark : theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: isDark ? const Color(0xFF404040) : theme.dividerColor),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
    );

    TextStyle fieldStyle = TextStyle(
      color: app.textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

    Widget timeBox(TextEditingController c, String hint) {
      return GestureDetector(
        onTap: () async {
          TimeOfDay initialTime;
          try {
            if (c.text.isNotEmpty) {
              final parts = c.text.split(':');
              initialTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            } else {
              initialTime = TimeOfDay.now();
            }
          } catch (_) {
            initialTime = TimeOfDay.now();
          }

          final picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final formatted = picked.hour.toString().padLeft(2, '0') +
                ':' +
                picked.minute.toString().padLeft(2, '0');
            setState(() => c.text = formatted);
          }
        },
        child: AbsorbPointer(
          child: Container(
            width: 130,
            height: kEntryHeight,
            decoration: fieldDecoration,
            alignment: Alignment.center,
            child: TextField(
              controller: c,
              textAlign: TextAlign.center,
              style: fieldStyle,
              maxLines: 1,
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: fieldStyle.copyWith(color: app.textColor),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      );
    }

    Widget selector(String text, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(kEntryRadius),
          onTap: onTap,
          child: Container(
            width: 130,
            height: kEntryHeight,
            decoration: fieldDecoration,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: fieldStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? app.cardColorDark : theme.cardColor,
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
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------- ALL FIELDS -------------
                Wrap(
                  spacing: kFieldSpacing,
                  runSpacing: kFieldSpacing,
                  children: [
                    timeBox(_startController, l10n.start),
                    timeBox(_endController, l10n.end),
                    selector(
                        _project ?? '${l10n.project} +', _showProjectPopup),
                    selector(
                      _expenses.containsKey('Per diem')
                          ? l10n.perDiem
                          : '${l10n.expenses} +',
                      _showExpensePopup,
                    ),
                    // Note field and Add button - will wrap to next line if needed
                    selector(_note ?? l10n.note, _showNotePopup),
                    SizedBox(
                      height: kEntryHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app.primaryBlue,
                          foregroundColor: app.whiteTextOnBlue,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(kEntryRadius)),
                          minimumSize: const Size(100, kEntryHeight),
                          maximumSize: const Size(120, kEntryHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _onAddPressed,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
