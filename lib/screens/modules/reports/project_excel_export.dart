import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class ProjectExcelExportService {
  /// Export multiple project reports to a single Excel file with multiple sheets
  static void exportExcelWithMultipleProjectSheets(
    Map<String, Map<String, dynamic>> projectReportData,
    Map<String, dynamic> reportConfig,
  ) {
    final workbook = xlsio.Workbook();

    var first = true;
    for (final entry in projectReportData.entries) {
      final projectData = entry.value;
      final projectName = projectData['projectName'] as String;
      final sessions = projectData['sessions'] as List<Map<String, dynamic>>;

      // Create or reuse first sheet
      final sheet = first ? workbook.worksheets[0] : workbook.worksheets.add();
      first = false;
      sheet.name = _cleanSheetName(projectName);
      
      // Get selected fields for dynamic content
      final selectedFields = (reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];

                           // Project Information - Vertical Layout
        sheet.getRangeByIndex(1, 1).setText('Project:');
        sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 12; // Same size as project name
        sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#4472C4'; // Blue background like project name
        sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF'; // White text like project name
        
        sheet.getRangeByIndex(1, 2).setText(projectName);
        sheet.getRangeByIndex(1, 2).cellStyle.backColor = '#4472C4'; // Blue background only for project name
        sheet.getRangeByIndex(1, 2).cellStyle.fontColor = '#FFFFFF'; // White text
        sheet.getRangeByIndex(1, 2).cellStyle.fontSize = 12;
        sheet.getRangeByIndex(1, 2).cellStyle.bold = true;
        
        // Add date range if available
        var currentRow = 2;
        if (reportConfig['dateRange'] != null) {
          final dateRange = reportConfig['dateRange'] as Map<String, dynamic>;
          final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
          final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
          
          if (startDate != null && endDate != null) {
            sheet.getRangeByIndex(currentRow, 1).setText('Report range:');
            sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
            sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
            sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
            sheet.getRangeByIndex(currentRow, 2).setText('${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}');
            sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
            sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
            currentRow++;
          }
        }
        
        // Project Reference
        sheet.getRangeByIndex(currentRow, 1).setText('Ref:');
        sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
        
        sheet.getRangeByIndex(currentRow, 2).setText(projectData['projectRef']?.toString() ?? '');
        sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
        sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
        currentRow++;
        
        // Project Address
        sheet.getRangeByIndex(currentRow, 1).setText('Address:');
        sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
        
        sheet.getRangeByIndex(currentRow, 2).setText(projectData['projectAddress']?.toString() ?? '');
        sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
        sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
        currentRow++;
        
        // Add borders to project info rows
        final projectInfoEndRow = currentRow - 1;
        for (int row = 1; row <= projectInfoEndRow; row++) {
          for (int col = 1; col <= 2; col++) {
            final cell = sheet.getRangeByIndex(row, col);
            cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
            cell.cellStyle.borders.all.color = '#000000';
          }
        }
        
        // Empty row after project info
        currentRow++;
       
       // Client Information - Vertical Layout
       sheet.getRangeByIndex(currentRow, 1).setText('Client name:');
       sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
       sheet.getRangeByIndex(currentRow, 2).setText(projectData['clientName']?.toString() ?? 'Unknown Client');
       sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
       currentRow++;
       
       // Client Address
       sheet.getRangeByIndex(currentRow, 1).setText('Address:');
       sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
       sheet.getRangeByIndex(currentRow, 2).setText(projectData['clientAddress']?.toString() ?? '');
       sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
       currentRow++;
       
       // Client Contact Person
       sheet.getRangeByIndex(currentRow, 1).setText('Contact:');
       sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
       sheet.getRangeByIndex(currentRow, 2).setText(projectData['clientContact']?.toString() ?? '');
       sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
       currentRow++;
       
       // Client Email
       sheet.getRangeByIndex(currentRow, 1).setText('Email:');
       sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
       sheet.getRangeByIndex(currentRow, 2).setText(projectData['clientEmail']?.toString() ?? '');
       sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
       currentRow++;
       
       // Client Phone
       sheet.getRangeByIndex(currentRow, 1).setText('Phone:');
       sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
       sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
       sheet.getRangeByIndex(currentRow, 2).setText(projectData['clientPhone']?.toString() ?? '');
       sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
       sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
       currentRow++;
       
       // Add borders to client info rows
       final clientInfoStartRow = currentRow - 5;
       final clientInfoEndRow = currentRow - 1;
       for (int row = clientInfoStartRow; row <= clientInfoEndRow; row++) {
         for (int col = 1; col <= 2; col++) {
           final cell = sheet.getRangeByIndex(row, col);
           cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
           cell.cellStyle.borders.all.color = '#000000';
         }
       }
       
       // Empty row after client info (before total sessions)
       currentRow++;
      
       // Dynamic summary section based on selected fields
       final summaryItems = <Map<String, dynamic>>[];
       if (selectedFields.contains('totalSessions')) {
         summaryItems.add({
           'label': 'Total Sessions:',
           'value': projectData['totalSessions']?.toString() ?? '0'
         });
       }
       if (selectedFields.contains('totalTime')) {
         summaryItems.add({
           'label': 'Total Time:',
           'value': projectData['totalTime']?.toString() ?? '0:00 h'
         });
       }
       if (selectedFields.contains('totalExpenses')) {
         summaryItems.add({
           'label': 'Total Expenses:',
           'value': '${projectData['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} CHF'
         });
       }
       
       // Add summary items to Excel
       for (final item in summaryItems) {
         sheet.getRangeByIndex(currentRow, 1).setText(item['label']);
         sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
         sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
         sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
         sheet.getRangeByIndex(currentRow, 2).setText(item['value']);
         sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
         sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
         currentRow++;
       }
       
       // Add borders to totals section if there are items
       if (summaryItems.isNotEmpty) {
         final totalsStartRow = currentRow - summaryItems.length;
         final totalsEndRow = currentRow - 1;
         for (int row = totalsStartRow; row <= totalsEndRow; row++) {
           for (int col = 1; col <= 2; col++) {
             final cell = sheet.getRangeByIndex(row, col);
             cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
             cell.cellStyle.borders.all.color = '#000000';
           }
         }
       }

                           // Table headers - dynamic based on selected fields
        final headers = <String>[];
        final fieldMappings = <String, String>{};
        var colIndex = 1;
        
        if (selectedFields.contains('date')) {
          headers.add('Date');
          fieldMappings['date'] = colIndex.toString();
          colIndex++;
        }
        if (selectedFields.contains('start')) {
          headers.add('Start');
          fieldMappings['start'] = colIndex.toString();
          colIndex++;
        }
        if (selectedFields.contains('end')) {
          headers.add('End');
          fieldMappings['end'] = colIndex.toString();
          colIndex++;
        }
        if (selectedFields.contains('duration')) {
          headers.add('Duration');
          fieldMappings['duration'] = colIndex.toString();
          colIndex++;
        }
        if (selectedFields.contains('worker')) {
          headers.add('Worker');
          fieldMappings['worker'] = colIndex.toString();
          colIndex++;
        }
        if (selectedFields.contains('expenses')) {
          headers.add('Expense Description');
          headers.add('Expense Amount');
          fieldMappings['expenses'] = colIndex.toString();
          colIndex += 2;
        }
        if (selectedFields.contains('note')) {
          headers.add('Note');
          fieldMappings['note'] = colIndex.toString();
          colIndex++;
        }
        
        final headerRow = currentRow + 1; // 1 empty row after totals, then headers
        for (var i = 0; i < headers.length; i++) {
          final headerCell = sheet.getRangeByIndex(headerRow, i + 1);
          headerCell.setText(headers[i]);
          headerCell.cellStyle.backColor = '#D9E2F3'; // Light blue background
          headerCell.cellStyle.fontColor = '#000000'; // Black text
          headerCell.cellStyle.fontSize = 11;
          headerCell.cellStyle.bold = true;
          headerCell.cellStyle.hAlign = xlsio.HAlignType.center;
          
          // Add borders to header cells
          headerCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          headerCell.cellStyle.borders.all.color = '#000000';
        }

             // Add data rows
       var rowIndex = headerRow + 1; // Start after headers
      for (final session in sessions) {
        var colIndex = 1;
        
        if (selectedFields.contains('date')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['Date']?.toString() ?? '');
          colIndex++;
        }
        
        if (selectedFields.contains('start')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['Start']?.toString() ?? '');
          colIndex++;
        }
        
        if (selectedFields.contains('end')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['End']?.toString() ?? '');
          colIndex++;
        }
        
        if (selectedFields.contains('duration')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['Duration']?.toString() ?? '');
          colIndex++;
        }
        
        if (selectedFields.contains('worker')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['Worker']?.toString() ?? '');
          colIndex++;
        }
        
        // Expense Description and Amount
        if (selectedFields.contains('expenses')) {
          final expenses = session['Expenses']?.toString() ?? '';
          if (expenses.isNotEmpty) {
            if (expenses.contains(',')) {
              // Multiple expenses - show first one in main row
              final firstExpense = expenses.split(',')[0].trim();
              if (firstExpense.contains(':')) {
                final parts = firstExpense.split(':');
                sheet.getRangeByIndex(rowIndex, colIndex).setText(parts[0].trim()); // Expense Description
                colIndex++;
                sheet.getRangeByIndex(rowIndex, colIndex).setText('${parts[1].trim()} CHF'); // Expense Amount
                colIndex++;
              } else {
                sheet.getRangeByIndex(rowIndex, colIndex).setText(firstExpense); // Expense Description
                colIndex++;
                sheet.getRangeByIndex(rowIndex, colIndex).setText('10.00 CHF'); // Expense Amount
                colIndex++;
              }
            } else {
              // Single expense
              if (expenses.contains(':')) {
                final parts = expenses.split(':');
                sheet.getRangeByIndex(rowIndex, colIndex).setText(parts[0].trim()); // Expense Description
                colIndex++;
                sheet.getRangeByIndex(rowIndex, colIndex).setText('${parts[1].trim()} CHF'); // Expense Amount
                colIndex++;
              } else {
                sheet.getRangeByIndex(rowIndex, colIndex).setText(expenses); // Expense Description
                colIndex++;
                sheet.getRangeByIndex(rowIndex, colIndex).setText('10.00 CHF'); // Expense Amount
                colIndex++;
              }
            }
          } else {
            // No expenses
            sheet.getRangeByIndex(rowIndex, colIndex).setText(''); // Expense Description
            colIndex++;
            sheet.getRangeByIndex(rowIndex, colIndex).setText(''); // Expense Amount
            colIndex++;
          }
        }
        
        if (selectedFields.contains('note')) {
          sheet.getRangeByIndex(rowIndex, colIndex).setText(session['Note']?.toString() ?? '');
          colIndex++;
        }
        
        // Format data row with borders
        for (int col = 1; col <= headers.length; col++) {
          final dataCell = sheet.getRangeByIndex(rowIndex, col);
          dataCell.cellStyle.fontSize = 10;
          dataCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          dataCell.cellStyle.borders.all.color = '#000000';
        }
        
        rowIndex++;
        
        // Add additional rows for multiple expenses (if more than one)
        if (selectedFields.contains('expenses')) {
          final sessionExpenses = session['Expenses']?.toString() ?? '';
          if (sessionExpenses.isNotEmpty && sessionExpenses.contains(',')) {
            final expenseList = sessionExpenses.split(',');
            for (int i = 1; i < expenseList.length; i++) {
              final expense = expenseList[i].trim();
              if (expense.isNotEmpty) {
                // Additional expense row - need to recreate the row with proper column positioning
                var expenseColIndex = 1;
                
                if (selectedFields.contains('date')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty date
                  expenseColIndex++;
                }
                
                if (selectedFields.contains('start')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty start
                  expenseColIndex++;
                }
                
                if (selectedFields.contains('end')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty end
                  expenseColIndex++;
                }
                
                if (selectedFields.contains('duration')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty duration
                  expenseColIndex++;
                }
                
                if (selectedFields.contains('worker')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty worker
                  expenseColIndex++;
                }
                
                // Expense Description and Amount
                if (expense.contains(':')) {
                  final parts = expense.split(':');
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(parts[0].trim()); // Expense Description
                  expenseColIndex++;
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText('${parts[1].trim()} CHF'); // Expense Amount
                  expenseColIndex++;
                } else {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(expense); // Expense Description
                  expenseColIndex++;
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText('10.00 CHF'); // Expense Amount
                  expenseColIndex++;
                }
                
                if (selectedFields.contains('note')) {
                  sheet.getRangeByIndex(rowIndex, expenseColIndex).setText(''); // Empty note
                  expenseColIndex++;
                }
                
                // Format expense row with borders for all columns
                for (int col = 1; col <= headers.length; col++) {
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
      
      // Auto-fit all columns
      for (int col = 1; col <= headers.length; col++) {
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
      ..download = '${reportConfig['name'] ?? 'multi_project_report'}.xlsx';
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
}
