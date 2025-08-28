import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/calendar.dart';

class ReportBuilderDialog extends StatefulWidget {
  final String companyId;
  final String userId;

  const ReportBuilderDialog({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<ReportBuilderDialog> createState() => _ReportBuilderDialogState();
}

class _ReportBuilderDialogState extends State<ReportBuilderDialog> {
  String _selectedOrientation = 'project';
  final Map<String, bool> _selectedFields = {};
  DateRange? _dateRange;
  String? _selectedProjectId;
  String? _selectedUserId;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  bool _isLoading = false;

  // Available report types
  final Map<String, String> _reportTypes = {
    'project': 'Project', 
    'user': 'User',
    'client': 'Client',
  };

  // Generate report name based on type and timestamp
  String _generateReportName() {
    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final type = _reportTypes[_selectedOrientation] ?? 'Report';
    return '$type $dateStr $timeStr';
  }

  // Available fields for each orientation
  final Map<String, List<Map<String, String>>> _availableFields = {
         'project': [
       {'key': 'totalSessions', 'label': 'Total Sessions'},
       {'key': 'totalTime', 'label': 'Total Time'},
       {'key': 'totalExpenses', 'label': 'Total Expenses'},
       {'key': 'date', 'label': 'Date'},
       {'key': 'start', 'label': 'Start'},
       {'key': 'end', 'label': 'End'},
       {'key': 'duration', 'label': 'Duration'},
       {'key': 'worker', 'label': 'Worker'},
       {'key': 'expenses', 'label': 'Expenses'},
       {'key': 'note', 'label': 'Note'},
     ],
         'user': [
       {'key': 'user', 'label': 'User Name'},
       {'key': 'totalHours', 'label': 'Total Hours'},
       {'key': 'totalExpenses', 'label': 'Total Expenses'},
       {'key': 'totalOvertime', 'label': 'Total Overtime'},
       {'key': 'timeOff', 'label': 'Vacation Balance'},
       {'key': 'project', 'label': 'Project'},
       {'key': 'start', 'label': 'Start'},
       {'key': 'end', 'label': 'End'},
       {'key': 'duration', 'label': 'Duration'},
       {'key': 'expenses', 'label': 'Expenses'},
       {'key': 'note', 'label': 'Note'},
     ],
    'client': [
      {'key': 'client', 'label': 'Client Name'},
      {'key': 'totalHours', 'label': 'Total Hours'},
      {'key': 'totalExpenses', 'label': 'Total Expenses'},
      {'key': 'projectCount', 'label': 'Total Projects'},
      {'key': 'revenue', 'label': 'Total Revenue'},
      {'key': 'profitMargin', 'label': 'Profit Margin'},
      {'key': 'lastActivity', 'label': 'Last Activity'},
    ],
    
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeFields();
  }

       void _initializeFields() {
    // Initialize with default fields for project orientation (default)
    final projectFields = _availableFields['project'] ?? [];
    for (final field in projectFields) {
      _selectedFields[field['key']!] = true; // All fields preselected by default
    }
  }

  Future<void> _loadData() async {
    try {
      // Load projects
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('projects')
          .get();

      // Load users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .get();

      // Load clients
      final clientsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('clients')
          .get();

      setState(() {
        _projects = projectsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _users = usersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _clients = clientsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
            
        // Data loaded for report builder
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onOrientationChanged(String orientation) {
    setState(() {
      _selectedOrientation = orientation;
      _selectedFields.clear();
      
      // Set default fields for the new orientation
      final fields = _availableFields[orientation] ?? [];
      final defaultFields = {
        'project': ['totalSessions', 'totalTime', 'totalExpenses', 'date', 'start', 'end', 'duration', 'worker', 'expenses', 'note'],
        'user': ['user', 'totalHours', 'totalExpenses', 'totalOvertime', 'timeOff', 'project', 'start', 'end', 'duration', 'expenses', 'note'],
        'client': ['client', 'totalHours', 'projectCount'],
      };
      
      for (final field in fields) {
        _selectedFields[field['key']!] = 
            defaultFields[orientation]?.contains(field['key']) ?? false;
      }
    });
  }

  Future<void> _saveReport() async {
    final selectedFields = _selectedFields.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one field')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Clean and validate data before saving
      final Map<String, dynamic> reportData = {
        'name': _generateReportName(),
        'orientation': _selectedOrientation,
        'fields': selectedFields,
        'createdBy': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Only add optional fields if they have values
      if (_dateRange != null) {
        final Map<String, dynamic> dateRangeData = {};
        if (_dateRange!.startDate != null) {
          dateRangeData['startDate'] = Timestamp.fromDate(_dateRange!.startDate!);
        }
        if (_dateRange!.endDate != null) {
          dateRangeData['endDate'] = Timestamp.fromDate(_dateRange!.endDate!);
        }
        if (dateRangeData.isNotEmpty) {
          reportData['dateRange'] = dateRangeData;
        }
      }

      // For project-oriented reports with client filter, don't set projectId to allow multiple projects
      if (_selectedProjectId != null && _selectedProjectId!.isNotEmpty && 
          !(_selectedOrientation == 'project' && _selectedClientId != null && _selectedClientId!.isNotEmpty)) {
        reportData['projectId'] = _selectedProjectId;
      }

      if (_selectedUserId != null && _selectedUserId!.isNotEmpty) {
        reportData['userId'] = _selectedUserId;
        // Saving report with userId
      } else {
        // No userId selected
      }

      if (_selectedClientId != null && _selectedClientId!.isNotEmpty) {
        reportData['clientId'] = _selectedClientId;
        // Saving report with clientId
      } else {
        // No clientId selected
      }

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('reports')
          .add(reportData);

      if (mounted) {
        Navigator.of(context).pop(reportData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report saved successfully!'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
          ),
        );
      }
    } catch (e) {
              // Error saving report
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${e.toString()}'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: colors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.createReport,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Type
                    Text(
                      'Report Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOrientation,
                          isExpanded: true,
                          items: _reportTypes.entries
                              .map((entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) _onOrientationChanged(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await showDialog<DateRange>(
                            context: context,
                            builder: (context) => Dialog(
                              child: CustomCalendar(
                                initialDateRange: _dateRange,
                                onDateRangeChanged: (range) {
                                  // Update the state directly, calendar handles its own closing
                                  setState(() {
                                    _dateRange = range;
                                  });
                                },
                                minDate: DateTime(2020),
                                maxDate: DateTime(2030),
                                showTodayIndicator: true,
                              ),
                            ),
                          );
                          // Calendar closes automatically when range is complete
                          // No need to handle result since state is updated in callback
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_dateRange != null
                            ? '${_dateRange!.startDate != null ? "${_dateRange!.startDate!.day.toString().padLeft(2, '0')}/${_dateRange!.startDate!.month.toString().padLeft(2, '0')}/${_dateRange!.startDate!.year}" : "Start"} - ${_dateRange!.endDate != null ? "${_dateRange!.endDate!.day.toString().padLeft(2, '0')}/${_dateRange!.endDate!.month.toString().padLeft(2, '0')}/${_dateRange!.endDate!.year}" : "End"}'
                            : 'Select Date Range'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.backgroundLight,
                          foregroundColor: colors.textColor,
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? colors.borderColorDark
                                : colors.borderColorLight,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Users Field
                    Text(
                      'Users',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedUserId,
                          isExpanded: true,
                          hint: const Text('Select User (All if empty)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Users'),
                            ),
                            ..._users.map((user) => DropdownMenuItem<String?>(
                                  value: user['id'],
                                  child: Text('${user['firstName'] ?? ''} ${user['surname'] ?? ''}'.trim().isEmpty
                                      ? user['email'] ?? 'Unknown User'
                                      : '${user['firstName'] ?? ''} ${user['surname'] ?? ''}'.trim()),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedUserId = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Projects Field
                    Text(
                      'Projects',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedProjectId,
                          isExpanded: true,
                          hint: const Text('Select Project (All if empty)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Projects'),
                            ),
                            ..._projects.map((project) => DropdownMenuItem<String?>(
                                  value: project['id'],
                                  child: Text(project['name'] ?? 'Unknown Project'),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedProjectId = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clients Field
                    Text(
                      'Clients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedClientId,
                          isExpanded: true,
                          hint: const Text('Select Client (All if empty)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Clients'),
                            ),
                            ..._clients.map((client) => DropdownMenuItem<String?>(
                                  value: client['id'],
                                  child: Text(client['name'] ?? 'Unknown Client'),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedClientId = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fields to Include
                    Text(
                      'Fields to Include',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: (_availableFields[_selectedOrientation] ?? [])
                            .map((field) => CheckboxListTile(
                                  title: Text(field['label']!),
                                  value: _selectedFields[field['key']] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFields[field['key']!] = value ?? false;
                                    });
                                  },
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
