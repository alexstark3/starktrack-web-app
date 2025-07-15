import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';

class MemberHistoryScreen extends StatefulWidget {
  final String companyId;
  final DocumentSnapshot memberDoc;
  final VoidCallback? onBack;

  const MemberHistoryScreen({
    Key? key,
    required this.companyId,
    required this.memberDoc,
    this.onBack,
  }) : super(key: key);

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  String _searchProjectOrDate = '';
  String _searchNotesExpenses = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final memberData = widget.memberDoc.data() as Map<String, dynamic>;
    final userId = widget.memberDoc.id;
    final userName = '${memberData['firstName'] ?? ''} ${memberData['surname'] ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Tabs remain visible at the top, let parent handle color changes/press logic ---
        // Main header with name and working status icon
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10, left: 0),
          child: Row(
            children: [
              Text(
                userName,
                style: TextStyle(
                  color: colors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 18),
              _StatusIcon(companyId: widget.companyId, userId: userId),
            ],
          ),
        ),
        _TotalsHeader(companyId: widget.companyId, userId: userId),
        const SizedBox(height: 10),

        // -- Two separate search fields --
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by project or date...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.midGray),
                  ),
                  filled: true,
                  fillColor: colors.lightGray,
                ),
                style: TextStyle(color: colors.textColor),
                onChanged: (val) => setState(() => _searchProjectOrDate = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search notes or expenses...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.midGray),
                  ),
                  filled: true,
                  fillColor: colors.lightGray,
                ),
                style: TextStyle(color: colors.textColor),
                onChanged: (val) => setState(() => _searchNotesExpenses = val.trim().toLowerCase()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: _LogsTable(
            companyId: widget.companyId,
            userId: userId,
            searchProjectOrDate: _searchProjectOrDate,
            searchNotesExpenses: _searchNotesExpenses,
            onAction: () => setState(() {}),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String companyId;
  final String userId;

  const _StatusIcon({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: todayStr)
          .snapshots(),
      builder: (context, snapshot) {
        bool isWorking = false;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final hasBegin = data['begin'] != null;
            final hasEnd = data['end'] != null;
            if (hasBegin && !hasEnd) {
              isWorking = true;
              break;
            }
          }
        }
        String status = isWorking ? '🟢 Working' : '🔴 Not working';
        return Text(status, style: const TextStyle(fontSize: 18));
      },
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final String companyId;
  final String userId;

  const _TotalsHeader({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .get(),
      builder: (context, snapshot) {
        double totalWork = 0;
        double totalExpenses = 0;
        int approvedCount = 0;
        int notApprovedCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalWork += (data['duration_minutes'] ?? 0).toDouble();
            final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
            totalExpenses += expenses.values.fold<double>(0, (sum, e) => sum + (e is num ? e : 0));
            if ((data['approved'] ?? false) == true) {
              approvedCount++;
            } else {
              notApprovedCount++;
            }
          }
        }
        return Row(
          children: [
            Text('Total Work: ${_fmtH(totalWork)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 18),
            Text('Total Expenses: ${totalExpenses.toStringAsFixed(2)} CHF', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 18),
            Text('Approved: $approvedCount | Not Approved: $notApprovedCount', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        );
      },
    );
  }
}

class _LogsTable extends StatefulWidget {
  final String companyId;
  final String userId;
  final String searchProjectOrDate;
  final String searchNotesExpenses;
  final VoidCallback onAction;

  const _LogsTable({
    required this.companyId,
    required this.userId,
    required this.searchProjectOrDate,
    required this.searchNotesExpenses,
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
      _allProjects = snap.docs.map((doc) => doc['name']?.toString() ?? '').toList();
    });
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

        // Filter logs by project or date
        if (widget.searchProjectOrDate.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final begin = (data['begin'] as Timestamp?)?.toDate();
            final project = (data['project'] ?? '').toString().toLowerCase();
            final search = widget.searchProjectOrDate;
            return (begin != null && DateFormat('yyyy-MM-dd').format(begin).contains(search)) ||
                project.contains(search);
          }).toList();
        }
        // Filter logs by notes or expenses
        if (widget.searchNotesExpenses.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final note = (data['note'] ?? '').toString().toLowerCase();
            final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
            final expString = expenses.entries.map((e) => '${e.key}:${e.value}').join(',').toLowerCase();
            final search = widget.searchNotesExpenses;
            return note.contains(search) || expString.contains(search);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No time logs found for this worker.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Approve')),
              DataColumn(label: Text('Edit')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Start')),
              DataColumn(label: Text('End')),
              DataColumn(label: Text('Project')),
              DataColumn(label: Text('Work (h)')),
              DataColumn(label: Text('Expenses')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Status')),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isApproved = (data['approved'] ?? false) == true;
              final begin = (data['begin'] as Timestamp?)?.toDate();
              final end = (data['end'] as Timestamp?)?.toDate();
              final workMins = (data['duration_minutes'] ?? 0) as int;
              final project = data['project'];
              final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
              final note = data['note'] ?? '';
              final statusIcon = isApproved
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.warning, color: Colors.red);

              // ---- PROJECT CELL with RED FLAG if empty ----
              Widget projectCell;
              if (project == null || (project is String && project.trim().isEmpty)) {
                projectCell = Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text('No Project!', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                );
              } else {
                projectCell = Text(project.toString());
              }

              return DataRow(
                color: isApproved
                    ? null
                    : MaterialStateProperty.all(Colors.red.withOpacity(0.07)),
                cells: [
                  // Approve
                  DataCell(
                    isApproved
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'Approve',
                            onPressed: () async {
                              await doc.reference.update({
                                'approved': true,
                                'approvedBy': widget.userId,
                                'approvedAt': FieldValue.serverTimestamp(),
                              });
                              widget.onAction();
                            },
                          ),
                  ),
                  // Edit
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit',
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => _EditLogDialog(
                            logDoc: doc,
                            projects: _allProjects,
                            onSaved: widget.onAction,
                          ),
                        );
                      },
                    ),
                  ),
                  DataCell(Text(begin != null ? DateFormat('yyyy-MM-dd').format(begin) : '')),
                  DataCell(Text(begin != null ? DateFormat('HH:mm').format(begin) : '')),
                  DataCell(Text(end != null ? DateFormat('HH:mm').format(end) : '')),
                  DataCell(projectCell),
                  DataCell(Text(_fmtH(workMins))),
                  DataCell(Text(
                    expenses.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                    style: const TextStyle(fontSize: 13),
                  )),
                  DataCell(Text(note, style: TextStyle(fontSize: 13))),
                  DataCell(statusIcon),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

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

  void _addExpense(String name, double amount) {
    setState(() {
      _expenses[name] = amount;
    });
  }

  void _removeExpense(String name) {
    setState(() {
      _expenses.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
  
    return AlertDialog(
      title: const Text('Edit Time Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start time
            TextField(
              controller: _startCtrl,
              decoration: const InputDecoration(labelText: 'Start Time (HH:mm)'),
              keyboardType: TextInputType.datetime,
            ),
            // End time
            TextField(
              controller: _endCtrl,
              decoration: const InputDecoration(labelText: 'End Time (HH:mm)'),
              keyboardType: TextInputType.datetime,
            ),
            // Project (dropdown)
            DropdownButtonFormField<String>(
              value: _projectValue,
              isExpanded: true,
              items: widget.projects.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _projectValue = val;
                  _projectError = false;
                });
              },
              decoration: const InputDecoration(labelText: 'Project'),
            ),
            if (_projectError)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'No Project selected!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            // Note
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 12),
            // Expenses (add/remove/edit)
            Row(
              children: [
                const Text('Expenses', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Expense',
                  onPressed: () async {
                    final nameCtrl = TextEditingController();
                    final amountCtrl = TextEditingController();
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add Expense'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty || double.tryParse(amountCtrl.text) == null) return;
                              Navigator.pop(ctx, {'name': nameCtrl.text.trim(), 'amount': double.parse(amountCtrl.text)});
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      _addExpense(result['name'], result['amount']);
                    }
                  },
                ),
              ],
            ),
            Column(
              children: _expenses.entries.map((e) {
                return Row(
                  children: [
                    Expanded(child: Text('${e.key}: ${e.value}')),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove Expense',
                      onPressed: () => _removeExpense(e.key),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Approval note (optional)
            TextField(
              decoration: const InputDecoration(labelText: 'Approval Note (optional)'),
              onChanged: (v) => _approvalNote = v.trim(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Save & Approve'),
          onPressed: () async {
            // Validate time and project
            DateTime start, end;
            try {
              final baseDay = (widget.logDoc['begin'] as Timestamp).toDate();
              final sParts = _startCtrl.text.split(':');
              final eParts = _endCtrl.text.split(':');
              start = DateTime(baseDay.year, baseDay.month, baseDay.day, int.parse(sParts[0]), int.parse(sParts[1]));
              end = DateTime(baseDay.year, baseDay.month, baseDay.day, int.parse(eParts[0]), int.parse(eParts[1]));
              if (!end.isAfter(start)) throw 'End before start';
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid start/end time')));
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
              'approvalNote': _approvalNote,
              'approved': true,
              'approvedAt': FieldValue.serverTimestamp(),
              'edited': true,
            });
            widget.onSaved();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

String _fmtH(num mins) {
  final h = (mins ~/ 60).toString().padLeft(2, '0');
  final m = (mins % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
