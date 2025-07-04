import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';

class AlignedInputButton extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool isButton;
  final double width;
  final double height;
  final FocusNode? focusNode;
  final Color? color;
  final Color? borderColor;
  final Color? textColor;
  final bool enabled;
  final bool centerText;
  final bool isAdd;

  const AlignedInputButton({
    super.key,
    required this.label,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.isButton = false,
    this.width = 120,
    this.height = 48,
    this.focusNode,
    this.color,
    this.borderColor,
    this.textColor,
    this.enabled = true,
    this.centerText = false,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: isAdd ? appColors.primaryBlue : color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled && isButton ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor ?? Colors.grey.shade400,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: centerText ? Alignment.center : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: isButton
                ? Text(
                    label,
                    textAlign: centerText ? TextAlign.center : TextAlign.left,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isAdd
                          ? Colors.white
                          : (textColor ?? Colors.black),
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  )
                : TextField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: readOnly,
                    enabled: enabled,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: textColor ?? Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: onTap,
                  ),
          ),
        ),
      ),
    );
  }
}

class TimeTrackerScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  final bool isTeamLeader;

  const TimeTrackerScreen({
    Key? key,
    required this.companyId,
    required this.userId,
    this.isTeamLeader = false,
  }) : super(key: key);

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen> {
  Duration todayWork = Duration.zero;
  Duration todayBreak = Duration.zero;
  List<Map<String, dynamic>> workLogs = [];
  bool perDiem = false;
  List<String> perDiemLogIds = [];
  final TextEditingController manualStart = TextEditingController();
  final TextEditingController manualEnd = TextEditingController();
  final FocusNode manualStartFocus = FocusNode();
  final FocusNode manualEndFocus = FocusNode();
  final TextEditingController noteController = TextEditingController();
  final List<String> projects = ['Project +', 'Project X', 'Project Y'];
  String selectedProject = 'Project +';
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  Map<String, bool> editingLogs = {}; // logId -> isEditing
  Map<String, TextEditingController> startCtrls = {};
  Map<String, TextEditingController> endCtrls = {};
  Map<String, String> noteVals = {};
  Map<String, String> projectVals = {};
  Map<String, String> originalNotes = {};

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _now = DateTime.now());
    });
    manualStartFocus.addListener(() {
      if (!manualStartFocus.hasFocus) _formatTimeOnBlur(manualStart);
    });
    manualEndFocus.addListener(() {
      if (!manualEndFocus.hasFocus) _formatTimeOnBlur(manualEnd);
    });
    _loadTodayLogs();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    manualStart.dispose();
    manualEnd.dispose();
    noteController.dispose();
    manualStartFocus.dispose();
    manualEndFocus.dispose();
    startCtrls.values.forEach((c) => c.dispose());
    endCtrls.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadTodayLogs() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(today)
        .collection('logs')
        .get();

    workLogs = [];
    perDiem = false;
    perDiemLogIds = [];
    for (var d in snapshot.docs) {
      final data = d.data();
      data['logId'] = d.id;
      if (data['type'] == 'per_diem') {
        perDiem = true;
        perDiemLogIds.add(d.id);
      } else {
        workLogs.add(data);
      }
    }
    workLogs.sort((a, b) {
      final ta = (a['begin'] as Timestamp).toDate();
      final tb = (b['begin'] as Timestamp).toDate();
      return ta.compareTo(tb);
    });

    todayWork = Duration.zero;
    for (final log in workLogs.where((l) => l['type'] == 'work')) {
      final b = (log['begin'] as Timestamp).toDate();
      final e = (log['end'] as Timestamp).toDate();
      todayWork += Duration(minutes: e.difference(b).inMinutes);
    }
    setState(() {
      editingLogs.clear();
      startCtrls.clear();
      endCtrls.clear();
      noteVals.clear();
      projectVals.clear();
      originalNotes.clear();
    });
  }

  void _formatTimeOnBlur(TextEditingController ctrl) {
    String input = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (input.length == 3) input = '0$input';
    if (input.length == 4) {
      String h = input.substring(0, 2);
      String m = input.substring(2, 4);
      if (int.tryParse(h)! > 23) h = '23';
      if (int.tryParse(m)! > 59) m = '59';
      ctrl.text = '$h:${m.padLeft(2, '0')}';
    }
  }

  String _formatInputTime(String value) {
    String input = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (input.length == 3) input = '0$input';
    if (input.length == 4) {
      String h = input.substring(0, 2);
      String m = input.substring(2, 4);
      if (int.tryParse(h)! > 23) h = '23';
      if (int.tryParse(m)! > 59) m = '59';
      return '$h:${m.padLeft(2, '0')}';
    }
    return value;
  }

  Future<void> _addManualSession() async {
    try {
      final start = DateFormat.Hm().parse(manualStart.text);
      final end = DateFormat.Hm().parse(manualEnd.text);
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final begin = DateTime(day.year, day.month, day.day, start.hour, start.minute);
      final finish = DateTime(day.year, day.month, day.day, end.hour, end.minute);
      final minutes = finish.difference(begin).inMinutes;
      if (minutes <= 0) throw Exception();
      for (final log in workLogs) {
        final b = (log['begin'] as Timestamp).toDate();
        final e = (log['end'] as Timestamp).toDate();
        if (begin.isBefore(e) && finish.isAfter(b)) {
          if (!(finish == b || begin == e)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Overlapping or duplicate session exists.'),
              backgroundColor: Colors.red,
            ));
            return;
          }
        }
      }
      await _saveLog(begin, finish, minutes, selectedProject, noteController.text.trim());
      manualStart.clear();
      manualEnd.clear();
      noteController.clear();
      setState(() {
        selectedProject = 'Project +';
      });
      await _loadTodayLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid time range.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _saveLog(DateTime begin, DateTime end, int minutes, String project, String note) async {
    final date = DateFormat('yyyy-MM-dd').format(begin);
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(date)
        .collection('logs')
        .doc();
    await ref.set({
      'type': 'work',
      'begin': begin,
      'end': end,
      'minutes': minutes,
      'project': project,
      'note': note,
      'approved': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showExpensePopup() async {
    if (perDiem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per Diem already added for today.'), backgroundColor: Colors.red),
      );
      return;
    }
    final expense = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add Expense'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'per_diem'),
            child: const Text('Per Diem 16.00 CHF'),
          ),
        ],
      ),
    );
    if (expense == 'per_diem') {
      await _togglePerDiem();
    }
  }

  Future<void> _togglePerDiem() async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(date)
        .collection('logs');
    if (!perDiem) {
      await ref.add({
        'type': 'per_diem',
        'amount': 16.00,
        'currency': 'CHF',
        'created_at': FieldValue.serverTimestamp(),
      });
      setState(() {
        perDiem = true;
      });
    }
    await _loadTodayLogs();
  }

  // Remove all per diem entries for today (handles duplicates/old bugs)
  Future<void> _removePerDiem() async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final query = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(date)
        .collection('logs')
        .where('type', isEqualTo: 'per_diem')
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
    setState(() {
      perDiem = false;
      perDiemLogIds = [];
    });
    await _loadTodayLogs();
  }

  Future<void> _deleteWorkLog(String logId) async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(date)
        .collection('logs')
        .doc(logId);
    await ref.delete();
    await _loadTodayLogs();
  }

  bool _isEditable(Map<String, dynamic> log) {
    final DateTime now = DateTime.now();
    final thisSunday = DateTime(now.year, now.month, now.day)
        .add(Duration(days: DateTime.sunday - now.weekday));
    final deadline = DateTime(thisSunday.year, thisSunday.month, thisSunday.day, 23, 59, 59);
    return !((log['approved'] ?? false) || now.isAfter(deadline));
  }

  DateTime? _parseTime(String value, DateTime referenceDay) {
    try {
      final t = DateFormat.Hm().parse(value);
      return DateTime(referenceDay.year, referenceDay.month, referenceDay.day, t.hour, t.minute);
    } catch (e) {
      return null;
    }
  }

  String _durationHhMm(Duration d) => d.inMinutes == 0
      ? '00:00h'
      : '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}h';

  Future<void> _showProjectPickerForLog(String logId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Project'),
        children: projects.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, p),
          child: Text(p),
        )).toList(),
      ),
    );
    if (result != null) setState(() => projectVals[logId] = result);
  }

  Future<String?> _showNoteDialog({String? initialNote}) async {
    final TextEditingController ctrl = TextEditingController(text: initialNote ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Enter your note...',
              border: OutlineInputBorder(),
              isDense: false,
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkAndBreakLogs(BuildContext context) {
    List<Widget> rows = [];
    if (workLogs.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No sessions yet.'),
        )
      ];
    }

    DateTime? prevEnd;
    todayBreak = Duration.zero;

    for (int i = 0; i < workLogs.length; i++) {
      final log = workLogs[i];
      final logId = log['logId'] ?? '';
      final editable = _isEditable(log);

      startCtrls.putIfAbsent(logId, () => TextEditingController(text: DateFormat.Hm().format((log['begin'] as Timestamp).toDate())));
      endCtrls.putIfAbsent(logId, () => TextEditingController(text: DateFormat.Hm().format((log['end'] as Timestamp).toDate())));
      noteVals.putIfAbsent(logId, () => log['note'] ?? '');
      projectVals.putIfAbsent(logId, () => log['project'] ?? '');
      originalNotes.putIfAbsent(logId, () => log['note'] ?? '');

      final b = (log['begin'] as Timestamp).toDate();
      final e = (log['end'] as Timestamp).toDate();
      final minutes = log['minutes'] ?? e.difference(b).inMinutes;

      // Break row
      if (prevEnd != null && b.isAfter(prevEnd)) {
        final breakDuration = b.difference(prevEnd);
        todayBreak += breakDuration;
        rows.add(
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  alignment: Alignment.centerLeft,
                  child: const Text('Break:', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                _inputField(
                  controller: TextEditingController(text: DateFormat.Hm().format(prevEnd)),
                  label: '',
                  width: 85,
                  enabled: false,
                ),
                const SizedBox(width: 6),
                const Text('–', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                _inputField(
                  controller: TextEditingController(text: DateFormat.Hm().format(b)),
                  label: '',
                  width: 85,
                  enabled: false,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 105,
                  child: Text('= ${_durationHhMm(breakDuration)}', style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Container()),
              ],
            ),
          ),
        );
      }

      // Work row
      rows.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                alignment: Alignment.centerLeft,
                child: const Text('Work:', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 85,
                child: editingLogs[logId] == true
                  ? TextField(
                      controller: startCtrls[logId],
                      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      onChanged: (val) {
                        final formatted = _formatInputTime(val);
                        if (val != formatted) {
                          startCtrls[logId]?.text = formatted;
                          startCtrls[logId]?.selection = TextSelection.collapsed(offset: formatted.length);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    )
                  : _inputField(controller: startCtrls[logId]!, label: '', width: 85, enabled: false),
              ),
              const SizedBox(width: 6),
              const Text('–', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              SizedBox(
                width: 85,
                child: editingLogs[logId] == true
                  ? TextField(
                      controller: endCtrls[logId],
                      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      onChanged: (val) {
                        final formatted = _formatInputTime(val);
                        if (val != formatted) {
                          endCtrls[logId]?.text = formatted;
                          endCtrls[logId]?.selection = TextSelection.collapsed(offset: formatted.length);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    )
                  : _inputField(controller: endCtrls[logId]!, label: '', width: 85, enabled: false),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 105,
                child: Text('= ${_durationHhMm(Duration(minutes: minutes))}', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 130,
                child: editingLogs[logId] == true
                  ? TextButton(
                      onPressed: () async {
                        await _showProjectPickerForLog(logId);
                        setState(() {});
                      },
                      child: Text(projectVals[logId] ?? '', style: const TextStyle(fontSize: 16)),
                    )
                  : Text('Project: ${projectVals[logId]}', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: editingLogs[logId] == true
                    // Note is edited via POPUP!
                    ? GestureDetector(
                        onTap: () async {
                          final editedNote = await _showNoteDialog(initialNote: noteVals[logId] ?? '');
                          if (editedNote != null) {
                            setState(() {
                              noteVals[logId] = editedNote;
                            });
                          }
                        },
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.grey.withOpacity(0.07),
                          ),
                          constraints: const BoxConstraints(minHeight: 38),
                          child: Text(
                            noteVals[logId]?.isEmpty ?? true ? 'Add note...' : noteVals[logId] ?? '',
                            style: TextStyle(
                              color: noteVals[logId]?.isEmpty ?? true ? Colors.grey : Colors.black,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.visible,
                            maxLines: 6,
                            softWrap: true,
                          ),
                        ),
                      )
                    : Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.withOpacity(0.07),
                        ),
                        constraints: const BoxConstraints(minHeight: 38),
                        child: Text(
                          noteVals[logId]?.isEmpty ?? true ? 'Add note...' : noteVals[logId] ?? '',
                          style: TextStyle(
                            color: noteVals[logId]?.isEmpty ?? true ? Colors.grey : Colors.black,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: 6,
                          softWrap: true,
                        ),
                      ),
              ),
              if (editable) ...[
                if (editingLogs[logId] != true)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                    onPressed: () {
                      setState(() {
                        editingLogs.clear();
                        editingLogs[logId] = true;
                        // backup original values
                        originalNotes[logId] = noteVals[logId] ?? '';
                      });
                    },
                  ),
                if (editingLogs[logId] == true) ...[
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.green),
                    tooltip: 'Save',
                    onPressed: () async {
                      await _saveEdit(logId, workLogs[i]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.orange),
                    tooltip: 'Cancel',
                    onPressed: () {
                      setState(() {
                        editingLogs[logId] = false;
                        // restore note if needed
                        noteVals[logId] = originalNotes[logId] ?? '';
                      });
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete session?'),
                        content: const Text('Are you sure you want to delete this work session?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          ElevatedButton(
                            child: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteWorkLog(logId);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      );
      prevEnd = e;
    }
    return rows;
  }

  Future<void> _saveEdit(String logId, Map<String, dynamic> log) async {
    final b = _parseTime(startCtrls[logId]?.text ?? '', (log['begin'] as Timestamp).toDate());
    final e = _parseTime(endCtrls[logId]?.text ?? '', (log['end'] as Timestamp).toDate());
    final minutes = (b != null && e != null) ? e.difference(b).inMinutes : null;
    if (b == null || e == null || minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Overlap logic (excluding the log being edited)
    for (final other in workLogs) {
      if (other['logId'] == logId) continue;
      final otherB = (other['begin'] as Timestamp).toDate();
      final otherE = (other['end'] as Timestamp).toDate();
      if (b.isBefore(otherE) && e.isAfter(otherB)) {
        if (!(e == otherB || b == otherE)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Overlapping or duplicate session exists.'), backgroundColor: Colors.red),
          );
          return;
        }
      }
    }
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('sessions')
        .doc(DateFormat('yyyy-MM-dd').format(b))
        .collection('logs')
        .doc(logId)
        .update({
      'begin': b,
      'end': e,
      'minutes': minutes,
      'note': noteVals[logId] ?? '',
      'project': projectVals[logId] ?? '',
    });
    setState(() {
      editingLogs[logId] = false;
    });
    await _loadTodayLogs();
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    double width = 120,
    bool enabled = true,
  }) {
    return SizedBox(
      width: width,
      height: 38,
      child: TextField(
        controller: controller,
        enabled: enabled,
        readOnly: !enabled,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: appColors.dashboardBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today date and clock (aligned with fields)
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 12),
              child: Text(
                'Today: ${DateFormat('dd MMM yyyy').format(_now)} – ${DateFormat('HH:mm').format(_now)}',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
            ),
            // Inputs Row (All fields/buttons identical!)
            Card(
              color: isDark ? appColors.lightGray : Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AlignedInputButton(
                      label: 'Start',
                      controller: manualStart,
                      width: 110,
                      isButton: false,
                      focusNode: manualStartFocus,
                      textColor: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    AlignedInputButton(
                      label: 'End',
                      controller: manualEnd,
                      width: 110,
                      isButton: false,
                      focusNode: manualEndFocus,
                      textColor: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    AlignedInputButton(
                      label: selectedProject,
                      isButton: true,
                      width: 130,
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Select Project'),
                            children: projects.map((p) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, p),
                              child: Text(p),
                            )).toList(),
                          ),
                        );
                        if (result != null) setState(() => selectedProject = result);
                      },
                      textColor: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    AlignedInputButton(
                      label: 'Expense +',
                      isButton: true,
                      width: 130,
                      onTap: _showExpensePopup,
                      textColor: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AlignedInputButton(
                        label: 'Note',
                        controller: noteController,
                        isButton: false,
                        textColor: Colors.black,
                        onTap: () async {
                          final editedNote = await _showNoteDialog(initialNote: noteController.text);
                          if (editedNote != null && editedNote != noteController.text) {
                            setState(() {
                              noteController.text = editedNote;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      height: 48,
                      child: AlignedInputButton(
                        label: 'Add',
                        isButton: true,
                        width: 90,
                        centerText: true,
                        textColor: Colors.white,
                        color: appColors.primaryBlue,
                        isAdd: true,
                        onTap: _addManualSession,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Summary chips (below time entry, before logs)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Row(
                children: [
                  Chip(
                    label: Text('Worked: ${_durationHhMm(todayWork)}'),
                    backgroundColor: appColors.green.withOpacity(0.1),
                    labelStyle: TextStyle(color: appColors.green, fontSize: 16),
                  ),
                  const SizedBox(width: 14),
                  Chip(
                    label: Text('Breaks: ${_durationHhMm(todayBreak)}'),
                    backgroundColor: appColors.primaryBlue.withOpacity(0.07),
                    labelStyle: TextStyle(color: appColors.primaryBlue, fontSize: 16),
                  ),
                  if (perDiem)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Chip(
                        label: const Text('Per Diem 16.00 CHF', style: TextStyle(fontSize: 16)),
                        backgroundColor: Colors.yellow.withOpacity(0.12),
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
                        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onDeleted: _removePerDiem,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Logs Table
            Expanded(
              child: Card(
                color: isDark ? appColors.lightGray : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  children: _buildWorkAndBreakLogs(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
