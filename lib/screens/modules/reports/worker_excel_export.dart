import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserExcelExportService {
  /// Export a single report to Excel format
  static void exportSingleReport(List<Map<String, dynamic>> reportData, Map<String, dynamic> reportConfig, {String? filename, Map<String, String>? translations}) {
    if (reportData.isEmpty) return;

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Report';

    // Add report header info
    sheet.getRangeByIndex(1, 1).setText(translations?['starkTrackDetailedSessionReport'] ?? 'Stark Track - Detailed Session Report');
    sheet.getRangeByIndex(2, 1).setText(translations?['reportNameLabel'] ?? 'Report Name:');
    sheet.getRangeByIndex(2, 2).setText(reportConfig['name'] ?? 'Detailed Report');
    
    // Add date range if available
    var currentRow = 3;
    if (reportConfig['dateRange'] != null) {
      final dateRange = reportConfig['dateRange'] as Map<String, dynamic>;
      final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
      final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
      
      if (startDate != null && endDate != null) {
        sheet.getRangeByIndex(currentRow, 1).setText(translations?['reportRange'] ?? 'Report range:');
        sheet.getRangeByIndex(currentRow, 2).setText('${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}');
        currentRow++;
      }
    }
    
    sheet.getRangeByIndex(currentRow, 1).setText(translations?['reportType'] ?? 'Report Type:');
    sheet.getRangeByIndex(currentRow, 2).setText((reportConfig['orientation'] as String? ?? 'time').toUpperCase());
    currentRow++;
    
    sheet.getRangeByIndex(currentRow, 1).setText(translations?['generated'] ?? 'Generated:');
    sheet.getRangeByIndex(currentRow, 2).setText(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));
    currentRow++;
    
    sheet.getRangeByIndex(currentRow, 1).setText(translations?['totalSessions'] ?? 'Total Sessions:');
    sheet.getRangeByIndex(currentRow, 2).setText(reportData.length.toString());

    if (reportData.isNotEmpty) {
      final headers = reportData.first.keys.toList();
      
      // Add headers
      final headerRow = currentRow + 1;
      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(headerRow, i + 1).setText(headers[i]);
      }
      
      // Add data rows
      for (var i = 0; i < reportData.length; i++) {
        final row = reportData[i];
        for (var j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = row[header]?.toString() ?? '';
          sheet.getRangeByIndex(i + headerRow + 1, j + 1).setText(value);
        }
      }
    }

    // Save to bytes
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // Download in browser
    final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename ?? '${reportConfig['name'] ?? (translations?['report'] ?? 'report')}.xlsx';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  /// Export multiple user reports to a single Excel file with multiple sheets
  static void exportExcelWithMultipleSheets(
    Map<String, Map<String, dynamic>> userReportData,
    Map<String, dynamic> reportConfig,
    {String? filename, Map<String, String>? translations}
  ) {


    final workbook = xlsio.Workbook();

    var first = true;
    for (final entry in userReportData.entries) {
      final userData = entry.value;
      final userName = userData['userName'] as String;
      final sessions = userData['sessions'] as List<Map<String, dynamic>>;

      // Create or reuse first sheet
      final sheet = first ? workbook.worksheets[0] : workbook.worksheets.add();
      first = false;
      sheet.name = _cleanSheetName(userName);

      // User summary header with formatting - User: and name on same row with same styling
      sheet.getRangeByIndex(1, 1).setText(translations?['userLabel'] ?? 'User:');
      sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#4472C4'; // Blue background
      sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF'; // White text
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      
      sheet.getRangeByIndex(1, 2).setText(userName);
      sheet.getRangeByIndex(1, 2).cellStyle.backColor = '#4472C4'; // Same blue background
      sheet.getRangeByIndex(1, 2).cellStyle.fontColor = '#FFFFFF'; // Same white text
      sheet.getRangeByIndex(1, 2).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(1, 2).cellStyle.bold = true;
      
      // Add underline border under the entire user header row
      final userHeaderRange = sheet.getRangeByIndex(1, 1, 1, 2);
      userHeaderRange.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thin;
      userHeaderRange.cellStyle.borders.bottom.color = '#000000';
      
      // Add date range if available
      if (reportConfig['dateRange'] != null) {
        final dateRange = reportConfig['dateRange'] as Map<String, dynamic>;
        final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
        final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
        
                 if (startDate != null && endDate != null) {
           sheet.getRangeByIndex(2, 1).setText(translations?['reportRange'] ?? 'Report range:');
           sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 11;
           sheet.getRangeByIndex(2, 1).cellStyle.bold = true;
           sheet.getRangeByIndex(2, 2).setText('${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}');
           sheet.getRangeByIndex(2, 2).cellStyle.fontSize = 11;
           
           // Add borders to report range row
           sheet.getRangeByIndex(2, 1).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
           sheet.getRangeByIndex(2, 1).cellStyle.borders.all.color = '#000000';
           sheet.getRangeByIndex(2, 2).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
           sheet.getRangeByIndex(2, 2).cellStyle.borders.all.color = '#000000';
           
           // Shift all other rows down by 1
           // Total Sessions
           sheet.getRangeByIndex(3, 1).setText(translations?['totalSessions'] ?? 'Total Sessions:');
        } else {
          // Total Sessions (no date range)
          sheet.getRangeByIndex(2, 1).setText(translations?['totalSessions'] ?? 'Total Sessions:');
        }
      } else {
        // Total Sessions (no date range)
        sheet.getRangeByIndex(2, 1).setText(translations?['totalSessions'] ?? 'Total Sessions:');
      }
      
      // Get the current row index for totals section
      final totalsStartRow = reportConfig['dateRange'] != null ? 3 : 2;
      
      sheet.getRangeByIndex(totalsStartRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(totalsStartRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalsStartRow, 2).setText(userData['totalSessions']?.toString() ?? '0');
      sheet.getRangeByIndex(totalsStartRow, 2).cellStyle.fontSize = 11;
      
      // Total Time
      sheet.getRangeByIndex(totalsStartRow + 1, 1).setText(translations?['totalTime'] ?? 'Total Time:');
      sheet.getRangeByIndex(totalsStartRow + 1, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(totalsStartRow + 1, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalsStartRow + 1, 2).setText(userData['totalTime']?.toString() ?? '0');
      sheet.getRangeByIndex(totalsStartRow + 1, 2).cellStyle.fontSize = 11;
      
      // Total Expenses
      sheet.getRangeByIndex(totalsStartRow + 2, 1).setText(translations?['totalExpenses'] ?? 'Total Expenses:');
      sheet.getRangeByIndex(totalsStartRow + 2, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(totalsStartRow + 2, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalsStartRow + 2, 2).setText('${userData['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} CHF');
      sheet.getRangeByIndex(totalsStartRow + 2, 2).cellStyle.fontSize = 11;
      
      // Overtime Balance
      sheet.getRangeByIndex(totalsStartRow + 3, 1).setText(translations?['overtimeBalance'] ?? 'Overtime Balance:');
      sheet.getRangeByIndex(totalsStartRow + 3, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(totalsStartRow + 3, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalsStartRow + 3, 2).setText(userData['totalOvertime']?.toString() ?? '0:00 h');
      sheet.getRangeByIndex(totalsStartRow + 3, 2).cellStyle.fontSize = 11;
      
      // Vacation Balance
      sheet.getRangeByIndex(totalsStartRow + 4, 1).setText(translations?['vacationBalance'] ?? 'Vacation Balance:');
      sheet.getRangeByIndex(totalsStartRow + 4, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(totalsStartRow + 4, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalsStartRow + 4, 2).setText(userData['vacationBalance']?.toString() ?? '0.0');
      sheet.getRangeByIndex(totalsStartRow + 4, 2).cellStyle.fontSize = 11;
      
      // Add borders to totals section
      final totalsEndRow = totalsStartRow + 4;
      for (int row = totalsStartRow; row <= totalsEndRow; row++) {
        for (int col = 1; col <= 2; col++) {
          final cell = sheet.getRangeByIndex(row, col);
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.all.color = '#000000';
        }
      }

      // Sessions table headers with formatting
      final headerRow = totalsEndRow + 3; // 1 empty row after totals, then headers
      sheet.getRangeByIndex(headerRow, 1).setText(translations?['date'] ?? 'Date');
      sheet.getRangeByIndex(headerRow, 2).setText(translations?['start'] ?? 'Start');
      sheet.getRangeByIndex(headerRow, 3).setText(translations?['end'] ?? 'End');
      sheet.getRangeByIndex(headerRow, 4).setText(translations?['duration'] ?? 'Duration');
      sheet.getRangeByIndex(headerRow, 5).setText(translations?['project'] ?? 'Project');
      sheet.getRangeByIndex(headerRow, 6).setText(translations?['expenses'] ?? 'Expenses');
      sheet.getRangeByIndex(headerRow, 7).setText(translations?['amount'] ?? 'Amount');
      sheet.getRangeByIndex(headerRow, 8).setText(translations?['note'] ?? 'Note');
      
      // Format headers
      for (int col = 1; col <= 8; col++) {
        final headerCell = sheet.getRangeByIndex(headerRow, col);
        headerCell.cellStyle.backColor = '#8EAADB'; // Light blue background
        headerCell.cellStyle.fontColor = '#000000'; // Black text
        headerCell.cellStyle.fontSize = 11;
        headerCell.cellStyle.bold = true;
        headerCell.cellStyle.hAlign = xlsio.HAlignType.center;
        
        // Add borders to header cells
        headerCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        headerCell.cellStyle.borders.all.color = '#000000';
      }

      // Data rows with grouping
      if (sessions.isNotEmpty) {
        final groupedSessions = _groupSessionsByTimePeriod(sessions);
        var rowIndex = headerRow + 1; // Start after headers

        for (final monthEntry in groupedSessions.values.first.entries) {
          final weeks = monthEntry.value;
          
          for (final weekEntry in weeks.entries) {
            final days = weekEntry.value;
            
            for (final dayEntry in days.entries) {
              final daySessions = dayEntry.value;
              
              // Sessions for this day (no empty separating row)
              for (int i = 0; i < daySessions.length; i++) {
                final session = daySessions[i];
                
                // Only show date in first row of the day
                if (i == 0) {
                  sheet.getRangeByIndex(rowIndex, 1).setText(session['Date'] ?? '');
                } else {
                  sheet.getRangeByIndex(rowIndex, 1).setText(''); // Empty date for subsequent rows
                }
                
                sheet.getRangeByIndex(rowIndex, 2).setText('${session['Start'] ?? ''} h');
                sheet.getRangeByIndex(rowIndex, 3).setText('${session['End'] ?? ''} h');
                sheet.getRangeByIndex(rowIndex, 4).setText('${session['Duration'] ?? ''} h');
                sheet.getRangeByIndex(rowIndex, 5).setText(session['Project'] ?? '');
                
                // Handle expenses - show first expense only in main row
                final expenses = session['Expenses']?.toString() ?? '';
                if (expenses.isNotEmpty) {
                  // Show first expense only in main row
                  final firstExpense = expenses.split(',')[0].trim();
                  if (firstExpense.contains(':')) {
                    final parts = firstExpense.split(':');
                    sheet.getRangeByIndex(rowIndex, 6).setText(parts[0].trim());
                    sheet.getRangeByIndex(rowIndex, 7).setText('${parts[1].trim()} CHF');
                  } else {
                    sheet.getRangeByIndex(rowIndex, 6).setText(firstExpense);
                    sheet.getRangeByIndex(rowIndex, 7).setText('10.00 CHF');
                  }
                } else {
                  sheet.getRangeByIndex(rowIndex, 6).setText('');
                  sheet.getRangeByIndex(rowIndex, 7).setText('');
                }
                
                sheet.getRangeByIndex(rowIndex, 8).setText(session['Note'] ?? '');
                
                // Format data row
                for (int col = 1; col <= 8; col++) {
                  final dataCell = sheet.getRangeByIndex(rowIndex, col);
                  dataCell.cellStyle.fontSize = 10;
                  dataCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
                  dataCell.cellStyle.borders.all.color = '#000000';
                }
                
                rowIndex++;
                
                // Add empty rows for additional expenses (if more than one)
                if (expenses.isNotEmpty && expenses.contains(',')) {
                  final expenseList = expenses.split(',');
                  for (int i = 1; i < expenseList.length; i++) {
                    final expense = expenseList[i].trim();
                    if (expense.isNotEmpty) {
                      // Empty row with just expense description and amount
                      if (expense.contains(':')) {
                        final parts = expense.split(':');
                        sheet.getRangeByIndex(rowIndex, 6).setText(parts[0].trim());
                        sheet.getRangeByIndex(rowIndex, 7).setText('${parts[1].trim()} CHF');
                      } else {
                        sheet.getRangeByIndex(rowIndex, 6).setText(expense);
                        sheet.getRangeByIndex(rowIndex, 7).setText('10.00 CHF');
                      }
                      
                      // Format expense row with borders for all columns
                      for (int col = 1; col <= 8; col++) {
                        final dataCell = sheet.getRangeByIndex(rowIndex, col);
                        dataCell.cellStyle.fontSize = 10;
                        dataCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
                        dataCell.cellStyle.borders.all.color = '#000000';
                      }
                      
                      rowIndex++;
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // Auto-fit all columns
      for (int col = 1; col <= 8; col++) {
        sheet.autoFitColumn(col);
      }
    }

    // Save to bytes
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // Download in browser
    final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename ?? '${reportConfig['name'] ?? 'multi_user_report'}.xlsx';
    anchor.click();
    web.URL.revokeObjectURL(url);
    

  }

  /// Clean sheet name for Excel compatibility
  static String _cleanSheetName(String name) {
    // Excel sheet names cannot contain: [ ] : * ? / \
    String cleanName = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), '');
    // Excel sheet names cannot be longer than 31 characters
    if (cleanName.length > 31) {
      cleanName = cleanName.substring(0, 31);
    }
    return cleanName;
  }

  /// Group sessions by time period (Year -> Month -> Week -> Day)
  static Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>> _groupSessionsByTimePeriod(
      List<Map<String, dynamic>> sessions) {
    final grouped = <String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>{};
    
    for (final session in sessions) {
      final month = session['Month'] as String? ?? '';
      final week = session['Week'] as String? ?? '';
      final day = session['Date'] as String? ?? '';
      
      // Group by: Year -> Month -> Week -> Day -> Sessions
      grouped.putIfAbsent('2025', () => {});
      grouped['2025']!.putIfAbsent(month, () => {});
      grouped['2025']![month]!.putIfAbsent(week, () => {});
      grouped['2025']![month]![week]!.putIfAbsent(day, () => []);
      
      // Add session to day group
      grouped['2025']![month]![week]![day]!.add(session);
    }
    
    return grouped;
  }
}
