import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';


class ReportViewerDialog extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> reportConfig;

  const ReportViewerDialog({
    super.key,
    required this.companyId,
    required this.reportConfig,
  });

  @override
  State<ReportViewerDialog> createState() => _ReportViewerDialogState();
}

class _ReportViewerDialogState extends State<ReportViewerDialog> {
  List<Map<String, dynamic>> _reportData = [];
  List<String> _columnHeaders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orientation = widget.reportConfig['orientation'] as String;
      final fields = List<String>.from(widget.reportConfig['fields'] ?? []);
      
      switch (orientation) {
        case 'time':
          await _generateTimeBasedReport(fields);
          break;
        case 'project':
          await _generateProjectBasedReport(fields);
          break;
        case 'worker':
          await _generateUserBasedReport(fields);
          break;
        case 'client':
          await _generateClientBasedReport(fields);
          break;
        case 'expense':
          await _generateExpenseReport(fields);
          break;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to generate report: $e';
      });
    }
  }

  Future<void> _generateTimeBasedReport(List<String> fields) async {
    final l10n = AppLocalizations.of(context)!;
    final dateRange = widget.reportConfig['dateRange'] as Map<String, dynamic>?;
    final projectId = widget.reportConfig['projectId'] as String?;
    final userId = widget.reportConfig['userId'] as String?;

    // Get all users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .get();

    // Get all projects for name lookup
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .get();

    final projectsMap = {
      for (var doc in projectsSnapshot.docs) doc.id: doc.data()['name'] ?? l10n.unnamedProject
    };

    // Get all clients for name lookup
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();

    final clientsMap = {
      for (var doc in clientsSnapshot.docs) doc.id: doc.data()['name'] ?? l10n.unnamedClient
    };

    List<Map<String, dynamic>> allLogs = [];

    for (final userDoc in usersSnapshot.docs) {
      if (userId != null && userDoc.id != userId) continue;

      final userData = userDoc.data();
      final userName = '${userData['firstName'] ?? ''} ${userData['surname'] ?? ''}'.trim();

      Query logsQuery = FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs');

      if (projectId != null) {
        logsQuery = logsQuery.where('project', isEqualTo: projectId);
      }

      final logsSnapshot = await logsQuery.get();

      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data() as Map<String, dynamic>;
        
        // Apply date filter
        if (dateRange != null) {
          final begin = logData['begin'] as Timestamp?;
          if (begin != null) {
            final logDate = begin.toDate();
            final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
            final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
            
            if (startDate != null && logDate.isBefore(startDate)) continue;
            if (endDate != null && logDate.isAfter(endDate)) continue;
          }
        }

        // Build row data based on selected fields
        final rowData = <String, dynamic>{};
        
        for (final field in fields) {
          switch (field) {
            case 'date':
              final begin = logData['begin'] as Timestamp?;
              rowData[l10n.date] = begin != null 
                  ? DateFormat('dd/MM/yyyy').format(begin.toDate())
                  : '';
              break;
            case 'worker':
              rowData[l10n.worker] = userName;
              break;
            case 'project':
              final projectId = logData['projectId'] as String?;
              rowData[l10n.project] = projectId != null 
                  ? projectsMap[projectId] ?? l10n.unknownProject
                  : '';
              break;
            case 'client':
              final projectId = logData['projectId'] as String?;
              if (projectId != null) {
                final projectDoc = await FirebaseFirestore.instance
                    .collection('companies')
                    .doc(widget.companyId)
                    .collection('projects')
                    .doc(projectId)
                    .get();
                final clientId = projectDoc.data()?['client'] as String?;
                rowData[l10n.client] = clientId != null 
                    ? clientsMap[clientId] ?? l10n.unknownClient
                    : '';
              } else {
                rowData[l10n.client] = '';
              }
              break;
            case 'startTime':
              final begin = logData['begin'] as Timestamp?;
              rowData[l10n.startTime] = begin != null 
                  ? DateFormat('HH:mm').format(begin.toDate())
                  : '';
              break;
            case 'endTime':
              final end = logData['end'] as Timestamp?;
              rowData[l10n.endTime] = end != null 
                  ? DateFormat('HH:mm').format(end.toDate())
                  : '';
              break;
            case 'duration':
              final minutes = logData['duration_minutes'] as int? ?? 0;
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              rowData[l10n.duration] = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} h';
              break;
            case 'note':
              rowData[l10n.notes] = logData['note'] ?? '';
              break;
            case 'expenses':
              final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
              final expenseDetails = <String>[];
              double total = 0.0;
              
              // Add individual expense items with details
              for (var entry in expenses.entries) {
                if (entry.value is num && entry.value > 0) {
                  expenseDetails.add('${entry.key}: CHF ${(entry.value as num).toStringAsFixed(2)}');
                  total += (entry.value as num).toDouble();
                }
              }
              
              // Add per diem if applicable
              if (logData['perDiem'] == true) {
                expenseDetails.add('${l10n.perDiem}: CHF 16.00');
                total += 16.0;
              }
              
              if (expenseDetails.isNotEmpty) {
                rowData[l10n.expenses] = expenseDetails.join(', ');
                rowData[l10n.totalExpenses] = 'CHF ${total.toStringAsFixed(2)}';
              } else {
                rowData[l10n.expenses] = '';
                rowData[l10n.totalExpenses] = 'CHF 0.00';
              }
              break;
            case 'perDiem':
              rowData[l10n.perDiem] = (logData['perDiem'] == true) ? 'Yes' : 'No';
              break;
          }
        }

        allLogs.add(rowData);
      }
    }

    // Sort by date if date field is included
    if (fields.contains('date')) {
      allLogs.sort((a, b) {
        final dateA = a[l10n.date] as String? ?? '';
        final dateB = b[l10n.date] as String? ?? '';
        return dateB.compareTo(dateA); // Most recent first
      });
    }

    _reportData = allLogs;
    _columnHeaders = fields.map((field) => _getFieldLabel(field, AppLocalizations.of(context)!)).toList();
  }

  Future<void> _generateProjectBasedReport(List<String> fields) async {
    final l10n = AppLocalizations.of(context)!;
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .get();

    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();

    final clientsMap = {
      for (var doc in clientsSnapshot.docs) doc.id: doc.data()['name'] ?? l10n.unnamedClient
    };

    List<Map<String, dynamic>> projectReports = [];

    for (final projectDoc in projectsSnapshot.docs) {
      final projectData = projectDoc.data();
      final projectName = projectData['name'] ?? l10n.unnamedProject;
      final clientId = projectData['client'] as String?;

      // Calculate totals for this project
      double totalHours = 0;
      double totalExpenses = 0;
      Set<String> uniqueUsers = {};
      List<DateTime> workDates = [];

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final logsSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userDoc.id)
            .collection('all_logs')
            .where('projectId', isEqualTo: projectDoc.id)
            .get();

        for (final logDoc in logsSnapshot.docs) {
          final logData = logDoc.data();
          final minutes = logData['duration_minutes'] as int? ?? 0;
          totalHours += minutes / 60.0;

          final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
          for (var value in expenses.values) {
            if (value is num) totalExpenses += value.toDouble();
          }

          uniqueUsers.add(userDoc.id);

          final begin = logData['begin'] as Timestamp?;
          if (begin != null) {
            workDates.add(begin.toDate());
          }
        }
      }

      // Build row data
      final rowData = <String, dynamic>{};
      
      for (final field in fields) {
        switch (field) {
          case 'project':
            rowData[l10n.project] = projectName;
            break;
          case 'client':
            rowData[l10n.client] = clientId != null ? clientsMap[clientId] ?? l10n.unknownClient : '';
            break;
          case 'totalHours':
            rowData[l10n.totalHours] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData[l10n.totalExpenses] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'userCount':
            rowData[l10n.usersInvolved] = uniqueUsers.length.toString();
            break;
          case 'avgHoursPerDay':
            if (workDates.isNotEmpty) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final avgHours = totalHours / uniqueDays.length;
              rowData[l10n.avgHoursPerDay] = '${avgHours.toStringAsFixed(1)} h';
            } else {
              rowData[l10n.avgHoursPerDay] = '0.0 h';
            }
            break;
          case 'dateRange':
            if (workDates.isNotEmpty) {
              workDates.sort();
              final start = DateFormat('dd/MM/yyyy').format(workDates.first);
              final end = DateFormat('dd/MM/yyyy').format(workDates.last);
              rowData[l10n.dateRange] = '$start - $end';
            } else {
              rowData[l10n.dateRange] = l10n.noActivity;
            }
            break;
          case 'status':
            rowData[l10n.status] = totalHours > 0 ? l10n.active : l10n.inactive;
            break;
        }
      }

      projectReports.add(rowData);
    }

    // Sort by total hours descending
    projectReports.sort((a, b) {
      final hoursA = double.tryParse(a[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = projectReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field, AppLocalizations.of(context)!)).toList();
  }

  Future<void> _generateUserBasedReport(List<String> fields) async {
    final l10n = AppLocalizations.of(context)!;
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .get();

    List<Map<String, dynamic>> userReports = [];

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userName = '${userData['firstName'] ?? ''} ${userData['surname'] ?? ''}'.trim();

      // Calculate totals for this user
      double totalHours = 0;
      double totalExpenses = 0;
      Set<String> uniqueProjects = {};
      List<DateTime> workDates = [];

      final logsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs')
          .get();

      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        final minutes = logData['duration_minutes'] as int? ?? 0;
        totalHours += minutes / 60.0;

        final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
        for (var value in expenses.values) {
          if (value is num) totalExpenses += value.toDouble();
        }

        final projectId = logData['projectId'] as String?;
        if (projectId != null) {
          uniqueProjects.add(projectId);
        }

        final begin = logData['begin'] as Timestamp?;
        if (begin != null) {
          workDates.add(begin.toDate());
        }
      }

      // Build row data
      final rowData = <String, dynamic>{};
      
      for (final field in fields) {
        switch (field) {
          case 'worker':
            rowData[l10n.worker] = userName;
            break;
          case 'totalHours':
            rowData[l10n.totalHours] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData[l10n.totalExpenses] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'projectCount':
            rowData[l10n.projectsWorked] = uniqueProjects.length.toString();
            break;
          case 'avgHoursPerDay':
            if (workDates.isNotEmpty) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final avgHours = totalHours / uniqueDays.length;
              rowData[l10n.avgHoursPerDay] = '${avgHours.toStringAsFixed(1)} h';
            } else {
              rowData[l10n.avgHoursPerDay] = '0.0 h';
            }
            break;
          case 'overtimeHours':
            // Get real overtime data from user document
            final userOvertimeData = userData['overtime'] as Map<String, dynamic>? ?? {};
            final overtimeMinutes = (userOvertimeData['current'] as int? ?? 0) + 
                                  (userOvertimeData['transferred'] as int? ?? 0) + 
                                  (userOvertimeData['bonus'] as int? ?? 0);
            final overtimeHours = overtimeMinutes / 60.0;
            rowData[l10n.overtimeHours] = '${overtimeHours.toStringAsFixed(1)} h';
            break;
          case 'vacationDays':
            // Get real vacation data from user document
            final vacationData = userData['annualLeaveDays'] as Map<String, dynamic>? ?? {};
            final usedDays = vacationData['used'] as double? ?? 0.0;
            rowData[l10n.vacationDays] = '${usedDays.toStringAsFixed(1)} days';
            break;
          case 'efficiency':
            // Calculate efficiency based on expected vs actual hours
            if (workDates.isNotEmpty && totalHours > 0) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final expectedHours = uniqueDays.length * 8.0; // Assuming 8h/day
              final efficiency = (totalHours / expectedHours * 100).clamp(0, 200);
              rowData[l10n.efficiencyRating] = '${efficiency.toStringAsFixed(1)}%';
            } else {
              rowData[l10n.efficiencyRating] = l10n.noData;
            }
            break;
        }
      }

      userReports.add(rowData);
    }

    // Sort by total hours descending
    userReports.sort((a, b) {
      final hoursA = double.tryParse(a[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = userReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field, AppLocalizations.of(context)!)).toList();
  }

  Future<void> _generateClientBasedReport(List<String> fields) async {
    final l10n = AppLocalizations.of(context)!;
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();

    List<Map<String, dynamic>> clientReports = [];

    for (final clientDoc in clientsSnapshot.docs) {
      final clientData = clientDoc.data();
      final clientName = clientData['name'] ?? l10n.unnamedClient;

      // Get projects for this client
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('projects')
          .where('client', isEqualTo: clientDoc.id)
          .get();

      double totalHours = 0;
      double totalExpenses = 0;
      DateTime? lastActivity;

      for (final projectDoc in projectsSnapshot.docs) {
        // Get all logs for this project
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .get();

        for (final userDoc in usersSnapshot.docs) {
          final logsSnapshot = await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('users')
              .doc(userDoc.id)
              .collection('all_logs')
              .where('projectId', isEqualTo: projectDoc.id)
              .get();

          for (final logDoc in logsSnapshot.docs) {
            final logData = logDoc.data();
            final minutes = logData['duration_minutes'] as int? ?? 0;
            totalHours += minutes / 60.0;

            final expenses = logData['expenses'] as Map<String, dynamic>? ?? {};
            for (var value in expenses.values) {
              if (value is num) totalExpenses += value.toDouble();
            }

            final begin = logData['begin'] as Timestamp?;
            if (begin != null) {
              final logDate = begin.toDate();
              if (lastActivity == null || logDate.isAfter(lastActivity)) {
                lastActivity = logDate;
              }
            }
          }
        }
      }

      // Build row data
      final rowData = <String, dynamic>{};
      
      for (final field in fields) {
        switch (field) {
          case 'client':
            rowData[l10n.client] = clientName;
            break;
          case 'totalHours':
            rowData[l10n.totalHours] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData[l10n.totalExpenses] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'projectCount':
            rowData[l10n.totalProjects] = projectsSnapshot.docs.length.toString();
            break;

        }
      }

      clientReports.add(rowData);
    }

    // Sort by total hours descending
    clientReports.sort((a, b) {
      final hoursA = double.tryParse(a[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b[l10n.totalHours]?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = clientReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field, AppLocalizations.of(context)!)).toList();
  }

  Future<void> _generateExpenseReport(List<String> fields) async {
    final l10n = AppLocalizations.of(context)!;
    // Generate time-based report first
    await _generateTimeBasedReport(fields);
    
    // Filter out entries with no expenses and add expense details
    final expenseEntries = <Map<String, dynamic>>[];
    
    for (final row in _reportData) {
      final expensesStr = row[l10n.totalExpenses] as String? ?? 'CHF 0.00';
      final expenseAmount = double.tryParse(expensesStr.replaceAll('CHF ', '')) ?? 0.0;
      
      if (expenseAmount > 0) {
        // Add expense type and description if available
        if (fields.contains('expenseType')) {
          row[l10n.expenseType] = l10n.mixed; // You could parse individual expense types
        }
        if (fields.contains('amount')) {
          row[l10n.amount] = expensesStr;
        }
        if (fields.contains('description')) {
          row[l10n.description] = row[l10n.notes] ?? '';
        }
        
        expenseEntries.add(row);
      }
    }
    
    _reportData = expenseEntries;
  }



  String _getFieldLabel(String field, AppLocalizations l10n) {
    switch (field) {
      case 'date':
        return l10n.date;
      case 'worker':
        return l10n.worker;
      case 'project':
        return l10n.project;
      case 'client':
        return l10n.client;
      case 'startTime':
        return l10n.startTime;
      case 'endTime':
        return l10n.endTime;
      case 'duration':
        return l10n.duration;
      case 'note':
        return l10n.notes;
      case 'expenses':
        return l10n.expenses;
      case 'perDiem':
        return l10n.perDiem;
      case 'totalHours':
        return l10n.totalHours;
      case 'totalExpenses':
        return l10n.totalExpenses;
      case 'userCount':
        return l10n.usersInvolved;
      case 'projectCount':
        return l10n.projectsWorked;
      case 'avgHoursPerDay':
        return l10n.avgHoursPerDay;
      case 'dateRange':
        return l10n.dateRange;
      case 'status':
        return l10n.status;
      case 'overtimeHours':
        return l10n.overtimeHours;
      case 'vacationDays':
        return l10n.vacationDays;
      case 'efficiency':
        return l10n.efficiencyRating;
      case 'amount':
        return l10n.amount;
      case 'expenseType':
        return l10n.expenseType;
      case 'description':
        return l10n.description;
      default:
        return field;
    }
  }

  void _showExportOptions() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportReport),
        content: Text(l10n.chooseExportFormat),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToCSV();
            },
            child: Text(l10n.csv),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToExcel();
            },
            child: Text(l10n.excel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _exportToCSV() {
    if (_reportData.isEmpty) return;

    // Create CSV content manually
    final csvContent = StringBuffer();
    

    
    // Add headers
    csvContent.writeln(_columnHeaders.map((h) => '"$h"').join(','));
    
    // Add data rows
    for (final row in _reportData) {
      final csvRow = _columnHeaders.map((header) {
        final value = row[header]?.toString() ?? '';
        return '"${value.replaceAll('"', '""')}"'; // Escape quotes
      }).join(',');
      csvContent.writeln(csvRow);
    }
    
    // Create download
    final csvString = csvContent.toString();
    final blob = web.Blob([csvString.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '${widget.reportConfig['name'] ?? 'report'}.csv';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.csvExportedSuccessfully)),
    );
  }

  void _exportToExcel() {
    final l10n = AppLocalizations.of(context)!;
    if (_reportData.isEmpty) return;

    // Create Excel-compatible HTML table with better styling
    final htmlContent = StringBuffer();
    htmlContent.writeln('<!DOCTYPE html>');
    htmlContent.writeln('<html>');
    htmlContent.writeln('<head>');
    htmlContent.writeln('<meta charset="UTF-8">');
    htmlContent.writeln('<title>${widget.reportConfig['name'] ?? l10n.report}</title>');
    htmlContent.writeln('<style>');
    htmlContent.writeln('body { font-family: Arial, sans-serif; margin: 20px; }');
    htmlContent.writeln('h1 { color: #2c5aa0; margin-bottom: 10px; }');
    htmlContent.writeln('h2 { color: #2c5aa0; margin-bottom: 10px; }');
    htmlContent.writeln('.report-info { margin-bottom: 20px; color: #666; }');
    htmlContent.writeln('table { border-collapse: collapse; width: 100%; margin-top: 10px; }');
    htmlContent.writeln('th { background-color: #2c5aa0; color: white; padding: 12px 8px; text-align: left; font-weight: bold; border: 1px solid #ddd; }');
    htmlContent.writeln('td { padding: 10px 8px; border: 1px solid #ddd; }');
    htmlContent.writeln('tr:nth-child(even) { background-color: #f9f9f9; }');
    htmlContent.writeln('tr:hover { background-color: #f5f5f5; }');
    htmlContent.writeln('.number { text-align: right; }');
    htmlContent.writeln('.center { text-align: center; }');
    htmlContent.writeln('</style>');
    htmlContent.writeln('</head>');
    htmlContent.writeln('<body>');
    
    // Report header with metadata
    htmlContent.writeln('<h1>Stark Track Report</h1>');
    htmlContent.writeln('<h2>${widget.reportConfig['name'] ?? l10n.unnamedReport}</h2>');
    htmlContent.writeln('<div class="report-info">');
    htmlContent.writeln('<p><strong>Report Type:</strong> ${(widget.reportConfig['orientation'] as String).toUpperCase()}</p>');
    htmlContent.writeln('<p><strong>Generated:</strong> ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</p>');
    htmlContent.writeln('<p><strong>Total Records:</strong> ${_reportData.length}</p>');
    
    // Show filters if any
    final dateRange = widget.reportConfig['dateRange'] as Map<String, dynamic>?;
    if (dateRange != null) {
      final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
      final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
      if (startDate != null && endDate != null) {
        htmlContent.writeln('<p><strong>Date Range:</strong> ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}</p>');
      }
    }
    
    final projectId = widget.reportConfig['projectId'] as String?;
    if (projectId != null) {
      htmlContent.writeln('<p><strong>Project Filter:</strong> Applied</p>');
    }
    
    final userId = widget.reportConfig['userId'] as String?;
    if (userId != null) {
      htmlContent.writeln('<p><strong>User Filter:</strong> Applied</p>');
    }
    
    htmlContent.writeln('</div>');
    
    htmlContent.writeln('<table>');
    
    // Add headers
    htmlContent.writeln('<thead><tr>');
    for (final header in _columnHeaders) {
      htmlContent.writeln('<th>$header</th>');
    }
    htmlContent.writeln('</tr></thead>');
    
    // Add data rows
    htmlContent.writeln('<tbody>');
    for (final row in _reportData) {
      htmlContent.writeln('<tr>');
      for (final header in _columnHeaders) {
        final value = row[header]?.toString() ?? '';
        // Apply special formatting for different data types
        String cssClass = '';
        if (value.contains('CHF') || value.contains(' h') || value.contains('%')) {
          cssClass = ' class="number"';
        }
        htmlContent.writeln('<td$cssClass>$value</td>');
      }
      htmlContent.writeln('</tr>');
    }
    htmlContent.writeln('</tbody>');
    htmlContent.writeln('</table>');
    
    // Add footer
    htmlContent.writeln('<div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px;">');
    htmlContent.writeln('<p>Report generated by Stark Track - Time Tracking & Project Management</p>');
    htmlContent.writeln('<p>Export Date: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}</p>');
    htmlContent.writeln('</div>');
    
    htmlContent.writeln('</body>');
    htmlContent.writeln('</html>');
    
    // Create download - Excel can open HTML tables
    final htmlString = htmlContent.toString();
    final blob = web.Blob([htmlString.toJS].toJS, web.BlobPropertyBag(type: 'application/vnd.ms-excel'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '${widget.reportConfig['name'] ?? 'report'}.xls';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.excelFileExportedSuccessfully)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportConfig['name'] ?? l10n.report,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.reportConfig['orientation'] as String).toUpperCase()} Report - ${_reportData.length} records',
                      style: TextStyle(
                        color: colors.textColor.withValues(alpha: 0.7),
                      ),
                    ),

                  ],
                ),
                Row(
                  children: [
                    if (!_isLoading && _reportData.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _showExportOptions,
                        icon: const Icon(Icons.download),
                        label: Text(AppLocalizations.of(context)!.export),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colors.textColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: colors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(color: colors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _generateReport,
                                child: Text(AppLocalizations.of(context)!.retry),
                              ),
                            ],
                          ),
                        )
                      : _reportData.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: colors.textColor.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.noDataFoundForThisReport,
                                    style: TextStyle(
                                      color: colors.textColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    colors.primaryBlue.withValues(alpha: 0.1),
                                  ),
                                  columns: _columnHeaders
                                      .map((header) => DataColumn(
                                            label: Text(
                                              header,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colors.textColor,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  rows: _reportData
                                      .map((row) => DataRow(
                                            cells: _columnHeaders
                                                .map((header) => DataCell(
                                                      Text(
                                                        row[header]?.toString() ?? '',
                                                        style: TextStyle(
                                                          color: colors.textColor,
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
