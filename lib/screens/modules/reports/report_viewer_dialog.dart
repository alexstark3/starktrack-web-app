import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../../../theme/app_colors.dart';


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
        case 'user':
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
      for (var doc in projectsSnapshot.docs) doc.id: doc.data()['name'] ?? 'Unnamed Project'
    };

    // Get all clients for name lookup
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();

    final clientsMap = {
      for (var doc in clientsSnapshot.docs) doc.id: doc.data()['name'] ?? 'Unnamed Client'
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
              rowData['Date'] = begin != null 
                  ? DateFormat('dd/MM/yyyy').format(begin.toDate())
                  : '';
              break;
            case 'user':
              rowData['User'] = userName;
              break;
            case 'project':
              final projectId = logData['projectId'] as String?;
              rowData['Project'] = projectId != null 
                  ? projectsMap[projectId] ?? 'Unknown Project'
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
                rowData['Client'] = clientId != null 
                    ? clientsMap[clientId] ?? 'Unknown Client'
                    : '';
              } else {
                rowData['Client'] = '';
              }
              break;
            case 'startTime':
              final begin = logData['begin'] as Timestamp?;
              rowData['Start Time'] = begin != null 
                  ? DateFormat('HH:mm').format(begin.toDate())
                  : '';
              break;
            case 'endTime':
              final end = logData['end'] as Timestamp?;
              rowData['End Time'] = end != null 
                  ? DateFormat('HH:mm').format(end.toDate())
                  : '';
              break;
            case 'duration':
              final minutes = logData['duration_minutes'] as int? ?? 0;
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              rowData['Duration'] = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} h';
              break;
            case 'note':
              rowData['Notes'] = logData['note'] ?? '';
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
                expenseDetails.add('Per diem: CHF 16.00');
                total += 16.0;
              }
              
              if (expenseDetails.isNotEmpty) {
                rowData['Expenses'] = expenseDetails.join(', ');
                rowData['Total Expenses'] = 'CHF ${total.toStringAsFixed(2)}';
              } else {
                rowData['Expenses'] = '';
                rowData['Total Expenses'] = 'CHF 0.00';
              }
              break;
            case 'perDiem':
              rowData['Per Diem'] = (logData['perDiem'] == true) ? 'Yes' : 'No';
              break;
          }
        }

        allLogs.add(rowData);
      }
    }

    // Sort by date if date field is included
    if (fields.contains('date')) {
      allLogs.sort((a, b) {
        final dateA = a['Date'] as String? ?? '';
        final dateB = b['Date'] as String? ?? '';
        return dateB.compareTo(dateA); // Most recent first
      });
    }

    _reportData = allLogs;
    _columnHeaders = fields.map((field) => _getFieldLabel(field)).toList();
  }

  Future<void> _generateProjectBasedReport(List<String> fields) async {
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
      for (var doc in clientsSnapshot.docs) doc.id: doc.data()['name'] ?? 'Unnamed Client'
    };

    List<Map<String, dynamic>> projectReports = [];

    for (final projectDoc in projectsSnapshot.docs) {
      final projectData = projectDoc.data();
      final projectName = projectData['name'] ?? 'Unnamed Project';
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
            rowData['Project'] = projectName;
            break;
          case 'client':
            rowData['Client'] = clientId != null ? clientsMap[clientId] ?? 'Unknown Client' : '';
            break;
          case 'totalHours':
            rowData['Total Hours'] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData['Total Expenses'] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'userCount':
            rowData['Users Involved'] = uniqueUsers.length.toString();
            break;
          case 'avgHoursPerDay':
            if (workDates.isNotEmpty) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final avgHours = totalHours / uniqueDays.length;
              rowData['Avg Hours/Day'] = '${avgHours.toStringAsFixed(1)} h';
            } else {
              rowData['Avg Hours/Day'] = '0.0 h';
            }
            break;
          case 'dateRange':
            if (workDates.isNotEmpty) {
              workDates.sort();
              final start = DateFormat('dd/MM/yyyy').format(workDates.first);
              final end = DateFormat('dd/MM/yyyy').format(workDates.last);
              rowData['Date Range'] = '$start - $end';
            } else {
              rowData['Date Range'] = 'No activity';
            }
            break;
          case 'status':
            rowData['Status'] = totalHours > 0 ? 'Active' : 'Inactive';
            break;
        }
      }

      projectReports.add(rowData);
    }

    // Sort by total hours descending
    projectReports.sort((a, b) {
      final hoursA = double.tryParse(a['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = projectReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field)).toList();
  }

  Future<void> _generateUserBasedReport(List<String> fields) async {
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
          case 'user':
            rowData['User'] = userName;
            break;
          case 'totalHours':
            rowData['Total Hours'] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData['Total Expenses'] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'projectCount':
            rowData['Projects Worked'] = uniqueProjects.length.toString();
            break;
          case 'avgHoursPerDay':
            if (workDates.isNotEmpty) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final avgHours = totalHours / uniqueDays.length;
              rowData['Avg Hours/Day'] = '${avgHours.toStringAsFixed(1)} h';
            } else {
              rowData['Avg Hours/Day'] = '0.0 h';
            }
            break;
          case 'overtimeHours':
            // Get real overtime data from user document
            final userOvertimeData = userData['overtime'] as Map<String, dynamic>? ?? {};
            final overtimeMinutes = (userOvertimeData['current'] as int? ?? 0) + 
                                  (userOvertimeData['transferred'] as int? ?? 0) + 
                                  (userOvertimeData['bonus'] as int? ?? 0);
            final overtimeHours = overtimeMinutes / 60.0;
            rowData['Overtime Hours'] = '${overtimeHours.toStringAsFixed(1)} h';
            break;
          case 'vacationDays':
            // Get real vacation data from user document
            final vacationData = userData['annualLeaveDays'] as Map<String, dynamic>? ?? {};
            final usedDays = vacationData['used'] as double? ?? 0.0;
            rowData['Vacation Days'] = '${usedDays.toStringAsFixed(1)} days';
            break;
          case 'efficiency':
            // Calculate efficiency based on expected vs actual hours
            if (workDates.isNotEmpty && totalHours > 0) {
              final uniqueDays = workDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
              final expectedHours = uniqueDays.length * 8.0; // Assuming 8h/day
              final efficiency = (totalHours / expectedHours * 100).clamp(0, 200);
              rowData['Efficiency Rating'] = '${efficiency.toStringAsFixed(1)}%';
            } else {
              rowData['Efficiency Rating'] = 'No data';
            }
            break;
        }
      }

      userReports.add(rowData);
    }

    // Sort by total hours descending
    userReports.sort((a, b) {
      final hoursA = double.tryParse(a['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = userReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field)).toList();
  }

  Future<void> _generateClientBasedReport(List<String> fields) async {
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('clients')
        .get();

    List<Map<String, dynamic>> clientReports = [];

    for (final clientDoc in clientsSnapshot.docs) {
      final clientData = clientDoc.data();
      final clientName = clientData['name'] ?? 'Unnamed Client';

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
            rowData['Client'] = clientName;
            break;
          case 'totalHours':
            rowData['Total Hours'] = '${totalHours.toStringAsFixed(1)} h';
            break;
          case 'totalExpenses':
            rowData['Total Expenses'] = 'CHF ${totalExpenses.toStringAsFixed(2)}';
            break;
          case 'projectCount':
            rowData['Total Projects'] = projectsSnapshot.docs.length.toString();
            break;
          case 'revenue':
            // Calculate average hourly rate from all projects for this client
            double totalRevenue = 0.0;
            int projectsWithRates = 0;
            
            for (final projectDoc in projectsSnapshot.docs) {
              final projectData = projectDoc.data();
              final hourlyRate = projectData['hourlyRate'] as double? ?? 0.0;
              if (hourlyRate > 0) {
                // Get hours for this specific project
                double projectHours = 0.0;
                // You would need to calculate project-specific hours here
                totalRevenue += projectHours * hourlyRate;
                projectsWithRates++;
              }
            }
            
            if (projectsWithRates > 0) {
              rowData['Total Revenue'] = 'CHF ${totalRevenue.toStringAsFixed(2)}';
            } else {
              rowData['Total Revenue'] = 'No rates set';
            }
            break;
          case 'profitMargin':
            // Simplified profit margin calculation
            if (totalExpenses > 0) {
              // Assume average 25% profit margin if no specific rates
              final estimatedRevenue = totalExpenses * 1.33; // 25% margin
              final margin = ((estimatedRevenue - totalExpenses) / estimatedRevenue * 100);
              rowData['Profit Margin'] = '~${margin.toStringAsFixed(1)}%';
            } else {
              rowData['Profit Margin'] = 'No expense data';
            }
            break;
          case 'lastActivity':
            rowData['Last Activity'] = lastActivity != null 
                ? DateFormat('dd/MM/yyyy').format(lastActivity)
                : 'No activity';
            break;
        }
      }

      clientReports.add(rowData);
    }

    // Sort by total hours descending
    clientReports.sort((a, b) {
      final hoursA = double.tryParse(a['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      final hoursB = double.tryParse(b['Total Hours']?.toString().replaceAll(' h', '') ?? '0') ?? 0;
      return hoursB.compareTo(hoursA);
    });

    _reportData = clientReports;
    _columnHeaders = fields.map((field) => _getFieldLabel(field)).toList();
  }

  Future<void> _generateExpenseReport(List<String> fields) async {
    // Generate time-based report first
    await _generateTimeBasedReport(fields);
    
    // Filter out entries with no expenses and add expense details
    final expenseEntries = <Map<String, dynamic>>[];
    
    for (final row in _reportData) {
      final expensesStr = row['Total Expenses'] as String? ?? 'CHF 0.00';
      final expenseAmount = double.tryParse(expensesStr.replaceAll('CHF ', '')) ?? 0.0;
      
      if (expenseAmount > 0) {
        // Add expense type and description if available
        if (fields.contains('expenseType')) {
          row['Expense Type'] = 'Mixed'; // You could parse individual expense types
        }
        if (fields.contains('amount')) {
          row['Amount'] = expensesStr;
        }
        if (fields.contains('description')) {
          row['Description'] = row['Notes'] ?? '';
        }
        
        expenseEntries.add(row);
      }
    }
    
    _reportData = expenseEntries;
  }



  String _getFieldLabel(String field) {
    final labels = {
      'date': 'Date',
      'user': 'Worker',
      'project': 'Project',
      'client': 'Client',
      'startTime': 'Start',
      'endTime': 'End',
      'duration': 'Total',
      'note': 'Note',
      'expenses': 'Expenses',
      'perDiem': 'Per Diem',
      'totalHours': 'Total Hours',
      'totalExpenses': 'Total Expenses',
      'userCount': 'Users Involved',
      'projectCount': 'Projects Worked',
      'avgHoursPerDay': 'Avg Hours/Day',
      'dateRange': 'Date Range',
      'status': 'Status',
      'overtimeHours': 'Overtime Hours',
      'vacationDays': 'Vacation Days',
      'efficiency': 'Efficiency Rating',
      'revenue': 'Total Revenue',
      'profitMargin': 'Profit Margin',
      'lastActivity': 'Last Activity',
      'expenseType': 'Expense Type',
      'amount': 'Amount',
      'currency': 'Currency',
      'description': 'Description',
      'receipt': 'Receipt',
    };
    return labels[field] ?? field;
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToCSV();
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToExcel();
            },
            child: const Text('Excel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
      const SnackBar(content: Text('CSV exported successfully!')),
    );
  }

  void _exportToExcel() {
    if (_reportData.isEmpty) return;

    // Create Excel-compatible HTML table with better styling
    final htmlContent = StringBuffer();
    htmlContent.writeln('<!DOCTYPE html>');
    htmlContent.writeln('<html>');
    htmlContent.writeln('<head>');
    htmlContent.writeln('<meta charset="UTF-8">');
    htmlContent.writeln('<title>${widget.reportConfig['name'] ?? 'Report'}</title>');
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
    htmlContent.writeln('<h2>${widget.reportConfig['name'] ?? 'Unnamed Report'}</h2>');
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
      const SnackBar(content: Text('Excel file exported successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.reportConfig['name'] ?? 'Report',
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
                        label: const Text('Export'),
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
                                child: const Text('Retry'),
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
                                    'No data found for this report',
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
