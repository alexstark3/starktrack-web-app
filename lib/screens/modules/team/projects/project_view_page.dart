import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';

class ProjectViewPage extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> project;
  final VoidCallback onClose;

  const ProjectViewPage({
    Key? key,
    required this.companyId,
    required this.project,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ProjectViewPage> createState() => _ProjectViewPageState();
}

class _ProjectViewPageState extends State<ProjectViewPage> {
  late Future<List<Map<String, dynamic>>> _logsFuture;

  // ---- DATE FILTERS (new) ----
  DateTime? _filterStart;
  DateTime? _filterEnd;

  Map<String, dynamic> _currentProject = {};

  Map<String, dynamic>? _clientInfo; // holds info for the selected client

  @override
  void initState() {
    super.initState();
    _currentProject = Map<String, dynamic>.from(widget.project);
    _logsFuture = _fetchProjectLogs();
    _fetchClientInfo();
  }

  void _fetchClientInfo() async {
    final clientId = (_currentProject['client'] ?? '').toString();
    if (clientId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('clients')
          .doc(clientId)
          .get();
      if (doc.exists) {
        setState(() {
          _clientInfo = doc.data();
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProjectLogs() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .get();
    final users = usersSnapshot.docs;

    final String projectId = (_currentProject['project_id'] ?? _currentProject['id'] ?? '').toString();
    final String projectName = (_currentProject['name'] ?? '').toString();

    List<Map<String, dynamic>> allLogs = [];
    for (final userDoc in users) {
      final userId = userDoc.id;
      final userData = userDoc.data();
      final userFirstName = userData['firstName'] ?? '';
      final userSurname = userData['surname'] ?? '';
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('projectId', isEqualTo: projectId.isNotEmpty ? projectId : projectName)
          .get();
      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        allLogs.add({
          ...logData,
          'userFirstName': userFirstName,
          'userSurname': userSurname,
          'userId': userId,
          'logId': logDoc.id,
        });
      }
    }
    return allLogs;
  }

  Future<void> _showEditDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EditProjectDialog(
        companyId: widget.companyId,
        project: _currentProject,
      ),
    );
    if (result != null) {
      setState(() {
        _currentProject = result;
      });
      _fetchClientInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final project = _currentProject;
    final String projectId = (project['project_id'] ?? project['id'] ?? '').toString();
    final String projectName = (project['name'] ?? '').toString();

    final address = project['address'];
    final addressString = address is Map
        ? [
            address['street'],
            address['number'],
            address['post_code'],
            address['city'],
          ]
              .where((e) => e != null && e.toString().isNotEmpty)
              .map((e) => e.toString())
              .join(' ')
        : (address?.toString() ?? '');

    final clientId = project['client'] ?? '';
    final clientName = _clientInfo?['name'] ?? clientId;
    final contactPersonMap = _clientInfo?['contact_person'] ?? {};
    final contactPerson = '${contactPersonMap['first_name'] ?? ''} ${contactPersonMap['surname'] ?? ''}'.trim();
    final phone = _clientInfo?['phone'] ?? '';
    final email = _clientInfo?['email'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top section: Project details
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 40, top: 38, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName.isNotEmpty ? projectName : 'No Project Name',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (projectId.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Project ID: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(projectId, maxLines: null, softWrap: true)),
                          ],
                        ),
                      if (addressString.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(addressString, maxLines: null, softWrap: true)),
                          ],
                        ),
                      if (clientName.toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Client Details', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryBlue)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Client: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(clientName.toString(), maxLines: null, softWrap: true)),
                          ],
                        ),
                        if (contactPerson.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contact Person: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(contactPerson, maxLines: null, softWrap: true)),
                            ],
                          ),
                        if (phone.toString().isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(phone.toString(), maxLines: null, softWrap: true)),
                            ],
                          ),
                        if (email.toString().isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(email.toString(), maxLines: null, softWrap: true)),
                            ],
                          ),
                      ]
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showEditDialog,
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          // --- Sessions and totals
          Expanded(
            child: Padding(
              // Make enough space for shadow to be visible
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return const Center(child: Text('No work sessions found for this project.'));
                  }

                  // ---- DATE FILTER logic ----
                  final filteredLogs = logs.where((log) {
                    DateTime? date;
                    try {
                      date = DateFormat('yyyy-MM-dd').parse(log['sessionDate'] ?? '');
                    } catch (_) {}
                    final afterStart = _filterStart == null || (date != null && !date.isBefore(_filterStart!));
                    final beforeEnd  = _filterEnd == null || (date != null && !date.isAfter(_filterEnd!));
                    return afterStart && beforeEnd;
                  }).toList();

                  int totalMinutes = filteredLogs.fold<int>(
                    0,
                    (sum, log) {
                      final raw = log['duration_minutes'];
                      final intVal = raw is int
                          ? raw
                          : (raw is double
                              ? raw.toInt()
                              : int.tryParse(raw?.toString() ?? '0') ?? 0);
                      return sum + intVal;
                    },
                  );
                  double totalExpenses = filteredLogs.fold<double>(0.0, (sum, log) {
                    final expenses = log['expenses'];
                    if (expenses is Map) {
                      for (var value in expenses.values) {
                        if (value is num) {
                          sum += value.toDouble();
                        } else if (value is String) {
                          sum += double.tryParse(value) ?? 0.0;
                        }
                      }
                    }
                    return sum;
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- DATE FILTER UI (NEW) ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 0),
                        child: Row(
                          children: [
                            // Start date picker
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_filterStart == null
                                  ? "Start"
                                  : DateFormat('dd.MM.yyyy').format(_filterStart!)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filterStart ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _filterStart = picked);
                              },
                            ),
                            const SizedBox(width: 10),
                            Text("to"),
                            const SizedBox(width: 10),
                            // End date picker
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_filterEnd == null
                                  ? "End"
                                  : DateFormat('dd.MM.yyyy').format(_filterEnd!)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filterEnd ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _filterEnd = picked);
                              },
                            ),
                            const SizedBox(width: 10),
                            if (_filterStart != null || _filterEnd != null)
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.redAccent),
                                onPressed: () => setState(() {
                                  _filterStart = null;
                                  _filterEnd = null;
                                }),
                                tooltip: "Clear filter",
                              ),
                          ],
                        ),
                      ),
                      // Totals
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              'Total work: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('${(totalMinutes / 60).floor()}h ${(totalMinutes % 60).toString().padLeft(2, '0')}min'),
                            const SizedBox(width: 24),
                            Text(
                              'Total expenses: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('${totalExpenses.toStringAsFixed(2)} CHF'),
                          ],
                        ),
                      ),
                      // Data list (not table): every log in a Card
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, idx) {
                            final log = filteredLogs[idx];
                            final userName = '${log['userFirstName'] ?? ''} ${log['userSurname'] ?? ''}'.trim();
                            final begin = log['begin'];
                            final end = log['end'];
                            String start = '';
                            String finish = '';
                            if (begin != null && begin is Timestamp) {
                              final dt = begin.toDate();
                              start = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                            if (end != null && end is Timestamp) {
                              final dt = end.toDate();
                              finish = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                            final duration = log['duration_minutes'];
                            final note = log['note'] ?? '';
                            final expenses = log['expenses'];
                            String expenseStr = '';
                            if (expenses is Map) {
                              expenseStr = expenses.entries.map((e) => '${e.key}: ${e.value}').join(', ');
                            }

                            final sessionDateRaw = log['sessionDate']?.toString() ?? '';
                            // Format date: 2025-07-11 -> 11.07.2025 (Fri)
                            String formattedDate = sessionDateRaw;
                            try {
                              final date = DateFormat('yyyy-MM-dd').parse(sessionDateRaw);
                              formattedDate = DateFormat('dd.MM.yyyy (EEE)', 'en').format(date);
                            } catch (_) {}

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: Theme.of(context).brightness == Brightness.dark ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [const Color(0xFF404040), const Color(0xFF2D2D2D)],
                                ) : null,
                                color: Theme.of(context).brightness == Brightness.dark ? null : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF505050), width: 1) : null,
                                boxShadow: Theme.of(context).brightness == Brightness.light ? [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                    offset: Offset(0, 3),
                                  ),
                                ] : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // First row: Name
                                    Text(
                                      'Worker: $userName',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    // Second row: Date on left, then Start, End, Minutes
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: colors.primaryBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Text('Start: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(start),
                                        const SizedBox(width: 12),
                                        Text('End: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(finish),
                                        const SizedBox(width: 12),
                                        Text('Minutes: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${duration ?? ''}'),
                                      ],
                                    ),
                                    if (expenseStr.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Expenses: ',
                                                style: TextStyle(fontWeight: FontWeight.bold)),
                                            Expanded(
                                              child: Text(
                                                expenseStr,
                                                maxLines: null,
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (note.toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Note: ',
                                                style: TextStyle(fontWeight: FontWeight.bold)),
                                            Expanded(
                                              child: Text(
                                                note.toString(),
                                                maxLines: null,
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Project Edit Dialog, only main fields and client picker ---
class EditProjectDialog extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> project;

  const EditProjectDialog({
    Key? key,
    required this.companyId,
    required this.project,
  }) : super(key: key);

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _projectIdCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _postCodeCtrl;
  late TextEditingController _cityCtrl;

  String? _selectedClientId;
  Map<String, dynamic> _clients = {};

  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p['name'] ?? '');
    _projectIdCtrl = TextEditingController(text: p['project_id'] ?? p['id'] ?? '');
    final addr = p['address'] as Map<String, dynamic>? ?? {};
    _streetCtrl = TextEditingController(text: addr['street'] ?? '');
    _numberCtrl = TextEditingController(text: addr['number'] ?? '');
    _postCodeCtrl = TextEditingController(text: addr['post_code'] ?? '');
    _cityCtrl = TextEditingController(text: addr['city'] ?? '');
    _selectedClientId = p['client']?.toString();

    _loadClients();
  }

  Future<void> _loadClients() async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();
    setState(() {
      _clients = { for (var doc in snap.docs) doc.id: doc.data() };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF404040) 
        : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: Theme.of(context).brightness == Brightness.dark 
          ? BorderSide(color: const Color(0xFF505050), width: 1)
          : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: colors.primaryBlue)),
              const SizedBox(height: 18),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Project Name'),
              ),
              TextField(
                controller: _projectIdCtrl,
                decoration: InputDecoration(labelText: 'Project ID'),
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _streetCtrl, decoration: InputDecoration(labelText: 'Street'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _numberCtrl, decoration: InputDecoration(labelText: 'No.'))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _postCodeCtrl, decoration: InputDecoration(labelText: 'Post Code'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _cityCtrl, decoration: InputDecoration(labelText: 'City'))),
                ],
              ),
              const SizedBox(height: 12),
              // --- Client picker ---
              DropdownButtonFormField<String>(
                value: _selectedClientId?.isNotEmpty == true ? _selectedClientId : null,
                items: _clients.entries.map((e) {
                  final name = e.value['name'] ?? e.key;
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(name.toString()),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Client'),
                onChanged: (val) => setState(() => _selectedClientId = val),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryBlue,
                      foregroundColor: colors.whiteTextOnBlue,
                    ),
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() {
                              _saving = true;
                              _error = '';
                            });
                            try {
                              final address = {
                                'street': _streetCtrl.text,
                                'number': _numberCtrl.text,
                                'post_code': _postCodeCtrl.text,
                                'city': _cityCtrl.text,
                              };
                              final update = {
                                'name': _nameCtrl.text.trim(),
                                'project_id': _projectIdCtrl.text.trim(),
                                'address': address,
                                'client': _selectedClientId ?? '',
                              };
                              final docId = widget.project['id'] ?? widget.project['project_id'];
                              if (docId == null || docId.toString().isEmpty) {
                                setState(() {
                                  _error = "Project document ID is missing!";
                                  _saving = false;
                                });
                                return;
                              }
                              await FirebaseFirestore.instance
                                  .collection('companies')
                                  .doc(widget.companyId)
                                  .collection('projects')
                                  .doc(docId.toString())
                                  .update(update);

                              Navigator.pop(context, {
                                ...widget.project,
                                ...update,
                                'address': address,
                                'id': docId,
                              });
                            } catch (e) {
                              setState(() {
                                _error = "Error: $e";
                                _saving = false;
                              });
                            }
                          },
                    child: _saving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
