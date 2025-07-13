import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starktrack/theme/app_colors.dart';

const double kEntryHeight = 38;
const double kEntryRadius = 9;
const double kFieldSpacing = 8;

class TimeEntryCard extends StatefulWidget {
  final String companyId;
  final String userId;
  final DateTime selectedDay;
  final List<String> projects;

  const TimeEntryCard({
    Key? key,
    required this.companyId,
    required this.userId,
    required this.selectedDay,
    required this.projects,
  }) : super(key: key);

  @override
  State<TimeEntryCard> createState() => _TimeEntryCardState();
}

class _TimeEntryCardState extends State<TimeEntryCard> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String? _project;
  String? _note;
  bool _isLoading = false;

  // Expenses logic
  Map<String, dynamic> _expenses = {};

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
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
                  onPressed: () => Navigator.pop(context, p),
                ))
            .toList(),
      ),
    );
    if (res != null) setState(() => _project = res);
  }

  Future<void> _showNotePopup() async {
    final ctrl = TextEditingController(text: _note ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Note'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) setState(() => _note = res.trim());
  }

  Future<void> _showExpensePopup() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(_expenses);
    bool tempPerDiem = tempExpenses.containsKey('Per diem');
    Color primaryColor = Colors.blue;

    // CHECK for Per Diem in any log for this day!
    final d = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final perDiemQuery = await FirebaseFirestore.instance
        .collection('companies').doc(widget.companyId)
        .collection('users').doc(widget.userId)
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
                Text('Per Diem',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: canEditPerDiem
                        ? Colors.black
                        : Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                const Text('16.00 CHF',
                    style: TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 16)),
                if (!canEditPerDiem)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: "Per Diem already used for this day",
                      child: Icon(Icons.lock, color: Colors.grey, size: 17),
                    ),
                  ),
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
                    _expenses = Map<String, dynamic>.from(tempExpenses);
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

  Future<bool> _hasOverlap(DateTime begin, DateTime end) async {
    final d = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final q = await FirebaseFirestore.instance
        .collection('companies').doc(widget.companyId)
        .collection('users').doc(widget.userId)
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

  Future<void> _onAddPressed() async {
    setState(() => _isLoading = true);
    try {
      final s = _startController.text.trim();
      final e = _endController.text.trim();
      if (s.isEmpty || e.isEmpty) throw 'Start and End times cannot be empty';

      final st = DateFormat.Hm().parse(s);
      final et = DateFormat.Hm().parse(e);
      final d  = widget.selectedDay;
      final begin = DateTime(d.year, d.month, d.day, st.hour, st.minute);
      final end   = DateTime(d.year, d.month, d.day, et.hour, et.minute);
      if (!end.isAfter(begin)) throw 'End time must be after start time';
      if (await _hasOverlap(begin, end)) throw 'Error: Time overlap';

      // Check Per Diem again before add!
      final dayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
      final perDiemQuery = await FirebaseFirestore.instance
          .collection('companies').doc(widget.companyId)
          .collection('users').doc(widget.userId)
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
        throw 'Per Diem already entered today';
      }

      final mins = end.difference(begin).inMinutes;
      final sessionDate = DateFormat('yyyy-MM-dd').format(d);

      await FirebaseFirestore.instance
          .collection('companies').doc(widget.companyId)
          .collection('users').doc(widget.userId)
          .collection('all_logs')
          .doc()
          .set({
        'sessionDate': sessionDate,
        'begin': begin,
        'end': end,
        'duration_minutes': mins,
        'project': _project ?? '',
        'note': _note ?? '',
        'expenses': _expenses,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _startController.clear();
        _endController.clear();
        _project = null;
        _note    = null;
        _expenses = {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --------- TIME PICKER (24h) ---------
  Widget timeBox(TextEditingController c, String hint) {
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boxShadow = [
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
        blurRadius: 1,
        offset: const Offset(0, 2),
      )
    ];
    BoxDecoration fieldDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(kEntryRadius),
      boxShadow: boxShadow,
      border: Border.all(color: theme.dividerColor),
    );
    TextStyle fieldStyle = TextStyle(
      color: app.textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

    return GestureDetector(
      onTap: () async {
        // Try to parse current text, fallback to now
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
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formatted = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
          setState(() => c.text = formatted);
        }
      },
      child: AbsorbPointer(
        child: Container(
          width: 92,
          height: kEntryHeight,
          decoration: fieldDecoration,
          alignment: Alignment.center,
          child: TextField(
            controller: c,
            textAlign: TextAlign.center,
            style: fieldStyle,
            maxLines: 1,
            readOnly: true, // This disables the keyboard!
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

  Widget selector(String text, VoidCallback onTap) {
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boxShadow = [
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
        blurRadius: 1,
        offset: const Offset(0, 2),
      )
    ];
    BoxDecoration fieldDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(kEntryRadius),
      boxShadow: boxShadow,
      border: Border.all(color: theme.dividerColor),
    );
    TextStyle fieldStyle = TextStyle(
      color: app.textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

    return InkWell(
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
  }

  @override
  Widget build(BuildContext context) {
    final app   = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boxShadow = [
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
        blurRadius: 1,
        offset: const Offset(0, 2),
      )
    ];

    // Responsive: check width
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600; // Adjust as needed

    final timeFields = [
      timeBox(_startController, 'Start'),
      const SizedBox(width: kFieldSpacing),
      timeBox(_endController, 'End'),
      const SizedBox(width: kFieldSpacing),
      selector(_project ?? 'Project +', _showProjectPopup),
      const SizedBox(width: kFieldSpacing),
      selector(_expenses.containsKey('Per diem') ? 'Per Diem' : 'Expenses +', _showExpensePopup),
    ];

    final noteAndAdd = [
      Expanded(
        child: selector(_note ?? 'Add Note', _showNotePopup),
      ),
      const SizedBox(width: kFieldSpacing),
      SizedBox(
        height: kEntryHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: app.primaryBlue,
            foregroundColor: theme.colorScheme.onPrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kEntryRadius)),
            minimumSize: const Size(60, kEntryHeight),
            maximumSize: const Size(86, kEntryHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _onAddPressed,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: boxShadow),
        child: Card(
          color: theme.cardColor,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: isPhone
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: kFieldSpacing,
                        runSpacing: kFieldSpacing,
                        children: timeFields,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: noteAndAdd,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ...timeFields,
                      const SizedBox(width: kFieldSpacing),
                      ...noteAndAdd,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
