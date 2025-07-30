import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

// Filter styling constants
const double kFilterHeight = 40.0;
const double kFilterRadius = 10.0;
const double kFilterSpacing = 12.0;
const double kFilterFontSize = 14.0;

// Helper function to format minutes to HH:mm
String _formatTimeFromMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

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

    final String projectId = (_currentProject['id'] ?? '').toString();

    List<Map<String, dynamic>> allLogs = [];
    for (final userDoc in users) {
      final userId = userDoc.id;
      final userData = userDoc.data();
      final userFirstName = userData['firstName'] ?? '';
      final userSurname = userData['surname'] ?? '';

      // Query for sessions with projectId matching the Firestore document ID
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('projectId', isEqualTo: projectId)
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
    final String projectRef = (project['projectRef'] ?? '').toString();
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
    final contactPerson =
        '${contactPersonMap['first_name'] ?? ''} ${contactPersonMap['surname'] ?? ''}'
            .trim();
    final phone = _clientInfo?['phone'] ?? '';
    final email = _clientInfo?['email'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top section: Project details
          Padding(
            padding:
                const EdgeInsets.only(left: 0, right: 0, top: 38, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName.isNotEmpty
                      ? projectName
                      : AppLocalizations.of(context)!.noProjectsFound,
                  style: TextStyle(
                    fontSize: 18, // Reduced from 22 to 18
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showEditDialog,
                  child: Text(AppLocalizations.of(context)!.edit),
                ),
                const SizedBox(height: 10),
                if (projectRef.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.projectRef}: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                          child:
                              Text(projectRef, maxLines: null, softWrap: true)),
                    ],
                  ),
                if (addressString.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.address}: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(addressString,
                              maxLines: null, softWrap: true)),
                    ],
                  ),
                if (clientName.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.clientDetails,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.primaryBlue)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.clientName}: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(clientName.toString(),
                              maxLines: null, softWrap: true)),
                    ],
                  ),
                  if (contactPerson.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppLocalizations.of(context)!.contactPerson}: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: Text(contactPerson,
                                maxLines: null, softWrap: true)),
                      ],
                    ),
                  if (phone.toString().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppLocalizations.of(context)!.phone}: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: Text(phone.toString(),
                                maxLines: null, softWrap: true)),
                      ],
                    ),
                  if (email.toString().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppLocalizations.of(context)!.email}: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: Text(email.toString(),
                                maxLines: null, softWrap: true)),
                      ],
                    ),
                ]
              ],
            ),
          ),
          // --- Sessions and totals
          Expanded(
            child: Padding(
              // Remove horizontal padding to match other lists
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return Center(
                        child: Text(
                            AppLocalizations.of(context)!.noTimeLogsFound));
                  }

                  // ---- DATE FILTER logic ----
                  final filteredLogs = logs.where((log) {
                    DateTime? date;
                    try {
                      date = DateFormat('yyyy-MM-dd')
                          .parse(log['sessionDate'] ?? '');
                    } catch (_) {}
                    final afterStart = _filterStart == null ||
                        (date != null && !date.isBefore(_filterStart!));
                    final beforeEnd = _filterEnd == null ||
                        (date != null && !date.isAfter(_filterEnd!));
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
                  double totalExpenses =
                      filteredLogs.fold<double>(0.0, (sum, log) {
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            final dateFormat = DateFormat('yyyy-MM-dd');

                            // Pill decoration
                            final pillDecoration = BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(kFilterRadius),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black26,
                                width: 1,
                              ),
                            );

                            // Start date picker
                            final startDatePicker = InkWell(
                              borderRadius:
                                  BorderRadius.circular(kFilterRadius),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filterStart ?? DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setState(() => _filterStart = picked);
                              },
                              child: Container(
                                height: kFilterHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                decoration: pillDecoration,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.date_range,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      _filterStart == null
                                          ? AppLocalizations.of(context)!.start
                                          : dateFormat.format(_filterStart!),
                                      style: TextStyle(
                                        color: _filterStart == null
                                            ? theme.colorScheme.primary
                                            : (isDark
                                                ? Colors.white.withOpacity(0.87)
                                                : Colors.black
                                                    .withOpacity(0.87)),
                                        fontWeight: FontWeight.w500,
                                        fontSize: kFilterFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            // End date picker
                            final endDatePicker = InkWell(
                              borderRadius:
                                  BorderRadius.circular(kFilterRadius),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filterEnd ?? DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setState(() => _filterEnd = picked);
                              },
                              child: Container(
                                height: kFilterHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                decoration: pillDecoration,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.date_range,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      _filterEnd == null
                                          ? AppLocalizations.of(context)!.end
                                          : dateFormat.format(_filterEnd!),
                                      style: TextStyle(
                                        color: _filterEnd == null
                                            ? theme.colorScheme.primary
                                            : (isDark
                                                ? Colors.white.withOpacity(0.87)
                                                : Colors.black
                                                    .withOpacity(0.87)),
                                        fontWeight: FontWeight.w500,
                                        fontSize: kFilterFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            // Clear filter button
                            final clearButton = Container(
                              height: kFilterHeight,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.primary.withOpacity(0.2)
                                    : theme.colorScheme.primary
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.refresh,
                                    color: theme.colorScheme.primary, size: 24),
                                tooltip:
                                    AppLocalizations.of(context)!.clearFilters,
                                onPressed: () {
                                  setState(() {
                                    _filterStart = null;
                                    _filterEnd = null;
                                  });
                                },
                              ),
                            );

                            // Check if we need to wrap (when screen is too narrow)
                            final needsWrap = constraints.maxWidth < 600;

                            if (needsWrap) {
                              // Wrap layout for small screens
                              return Wrap(
                                spacing: kFilterSpacing,
                                runSpacing: 8,
                                children: [
                                  startDatePicker,
                                  endDatePicker,
                                  if (_filterStart != null ||
                                      _filterEnd != null)
                                    clearButton,
                                ],
                              );
                            } else {
                              // Single row layout for larger screens
                              return Row(
                                children: [
                                  startDatePicker,
                                  const SizedBox(width: kFilterSpacing),
                                  endDatePicker,
                                  const SizedBox(width: kFilterSpacing),
                                  if (_filterStart != null ||
                                      _filterEnd != null)
                                    clearButton,
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      // Totals
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.total}: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    '${_formatTimeFromMinutes(totalMinutes.toInt())} h'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.totalExpenses}: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${totalExpenses.toStringAsFixed(2)} CHF'),
                              ],
                            ),
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
                            final userName =
                                '${log['userFirstName'] ?? ''} ${log['userSurname'] ?? ''}'
                                    .trim();
                            final begin = log['begin'];
                            final end = log['end'];
                            String start = '';
                            String finish = '';
                            if (begin != null && begin is Timestamp) {
                              final dt = begin.toDate();
                              start =
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                            if (end != null && end is Timestamp) {
                              final dt = end.toDate();
                              finish =
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                            final duration = log['duration_minutes'];
                            final note = log['note'] ?? '';
                            final expenses = log['expenses'];
                            String expenseStr = '';
                            if (expenses is Map) {
                              expenseStr = expenses.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', ');
                            }

                            final sessionDateRaw =
                                log['sessionDate']?.toString() ?? '';
                            // Format date: 2025-07-11 -> 11.07.2025 (Fri)
                            String formattedDate = sessionDateRaw;
                            try {
                              final date = DateFormat('yyyy-MM-dd')
                                  .parse(sessionDateRaw);
                              formattedDate =
                                  DateFormat('dd.MM.yyyy (EEE)', 'en')
                                      .format(date);
                            } catch (_) {}

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors.cardColorDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Border.all(
                                        color: const Color(0xFF404040),
                                        width: 1)
                                    : null,
                                boxShadow: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          spreadRadius: 0,
                                          offset: Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Worker name with wrapping
                                    Text(
                                      '${AppLocalizations.of(context)!.worker}: $userName',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: null,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    // Date on its own line, left aligned
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: colors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Time line starting with Start
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context)!.start}: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(start),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context)!.end}: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(finish),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context)!.total}: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                '${_formatTimeFromMinutes(duration ?? 0)} h'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (expenseStr.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context)!.expenses}: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(
                                              expenseStr,
                                              maxLines: null,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (note.toString().isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${AppLocalizations.of(context)!.note}: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
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
    _projectIdCtrl =
        TextEditingController(text: p['projectRef'] ?? p['id'] ?? '');
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
      _clients = {for (var doc in snap.docs) doc.id: doc.data()};
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? colors.cardColorDark
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: Theme.of(context).brightness == Brightness.dark
            ? BorderSide(color: const Color(0xFF404040), width: 1)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.editProject,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: colors.primaryBlue)),
              const SizedBox(height: 18),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.projectName),
              ),
              TextField(
                controller: _projectIdCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.projectRef),
              ),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _streetCtrl,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.street))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _numberCtrl,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.number))),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _postCodeCtrl,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.postCode))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _cityCtrl,
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.city))),
                ],
              ),
              const SizedBox(height: 12),
              // --- Client picker ---
              DropdownButtonFormField<String>(
                value: _selectedClientId?.isNotEmpty == true
                    ? _selectedClientId
                    : null,
                items: _clients.entries.map((e) {
                  final name = e.value['name'] ?? e.key;
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(name.toString()),
                  );
                }).toList(),
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.client),
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
                    child: Text(AppLocalizations.of(context)!.cancel),
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
                                'projectRef': _projectIdCtrl.text.trim(),
                                'address': address,
                                'client': _selectedClientId ?? '',
                              };
                              final docId = widget.project['id'];
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
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
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
