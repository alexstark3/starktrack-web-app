import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClientExcelExportService {
  /// Export multiple client reports to a single Excel file with multiple sheets
  static void exportExcelWithMultipleClientSheets(
    Map<String, Map<String, dynamic>> clientReportData,
    Map<String, dynamic> reportConfig,
  ) {
    final workbook = xlsio.Workbook();

    var first = true;
    for (final entry in clientReportData.entries) {
      final clientData = entry.value;
      final clientName = clientData['clientName'] as String;
      final projects = clientData['projects'] as List<Map<String, dynamic>>;

      // Create or reuse first sheet
      final sheet = first ? workbook.worksheets[0] : workbook.worksheets.add();
      first = false;
      sheet.name = _cleanSheetName(clientName);
      
      // Get selected fields for dynamic content
      final selectedFields = (reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];

      // Client Information - Vertical Layout
      sheet.getRangeByIndex(1, 1).setText('Client:');
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#4472C4';
      sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF';
      
      sheet.getRangeByIndex(1, 2).setText(clientName);
      sheet.getRangeByIndex(1, 2).cellStyle.backColor = '#4472C4';
      sheet.getRangeByIndex(1, 2).cellStyle.fontColor = '#FFFFFF';
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
      
      // Client Address
      sheet.getRangeByIndex(currentRow, 1).setText('Address:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientAddress']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Client Contact Person
      sheet.getRangeByIndex(currentRow, 1).setText('Contact Person:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientContact']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Client Email
      sheet.getRangeByIndex(currentRow, 1).setText('Email:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientEmail']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Client Phone
      sheet.getRangeByIndex(currentRow, 1).setText('Phone:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientPhone']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Client City
      sheet.getRangeByIndex(currentRow, 1).setText('City:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientCity']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Client Country
      sheet.getRangeByIndex(currentRow, 1).setText('Country:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['clientCountry']?.toString() ?? '');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Add borders to client info rows
      final clientInfoEndRow = currentRow - 1;
      for (int row = 1; row <= clientInfoEndRow; row++) {
        for (int col = 1; col <= 2; col++) {
          final cell = sheet.getRangeByIndex(row, col);
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.all.color = '#000000';
        }
      }
      
      // Empty row after client info
      currentRow++;
      
      // Client Summary
      sheet.getRangeByIndex(currentRow, 1).setText('Client Summary:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#4472C4';
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = '#FFFFFF';
      currentRow++;
      
      // Total Projects
      sheet.getRangeByIndex(currentRow, 1).setText('Total Projects:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['totalProjects']?.toString() ?? '0');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Total Time
      sheet.getRangeByIndex(currentRow, 1).setText('Total Time:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText(clientData['totalTime']?.toString() ?? '0:00 h');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Total Expenses
      sheet.getRangeByIndex(currentRow, 1).setText('Total Expenses:');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.backColor = '#E7E6E6';
      
      sheet.getRangeByIndex(currentRow, 2).setText('${clientData['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} CHF');
      sheet.getRangeByIndex(currentRow, 2).cellStyle.fontSize = 11;
      sheet.getRangeByIndex(currentRow, 2).cellStyle.backColor = '#E7E6E6';
      currentRow++;
      
      // Add borders to summary section
      final summaryStartRow = currentRow - 3;
      final summaryEndRow = currentRow - 1;
      for (int row = summaryStartRow; row <= summaryEndRow; row++) {
        for (int col = 1; col <= 2; col++) {
          final cell = sheet.getRangeByIndex(row, col);
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.all.color = '#000000';
        }
      }
      
      // Empty row after summary
      currentRow++;
      
      // Projects table headers - dynamic based on selected fields
      final headerRow = currentRow;
      final columns = <String>[];
      final headers = <String>[];
      
      if (selectedFields.contains('projectName') || selectedFields.isEmpty) {
        columns.add('projectName');
        headers.add('Project Name');
      }
      if (selectedFields.contains('projectRef') || selectedFields.isEmpty) {
        columns.add('projectRef');
        headers.add('Reference');
      }
      if (selectedFields.contains('projectAddress') || selectedFields.isEmpty) {
        columns.add('projectAddress');
        headers.add('Address');
      }
      if (selectedFields.contains('totalTime') || selectedFields.isEmpty) {
        columns.add('totalTime');
        headers.add('Total Time');
      }
      if (selectedFields.contains('totalExpenses') || selectedFields.isEmpty) {
        columns.add('totalExpenses');
        headers.add('Total Expenses');
      }
      
      // Add headers dynamically
      for (int col = 0; col < headers.length; col++) {
        sheet.getRangeByIndex(headerRow, col + 1).setText(headers[col]);
        final cell = sheet.getRangeByIndex(headerRow, col + 1);
        cell.cellStyle.fontSize = 11;
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = '#4472C4';
        cell.cellStyle.fontColor = '#FFFFFF';
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        cell.cellStyle.borders.all.color = '#000000';
      }
      
      currentRow++;
      
      // Add project data dynamically
      for (final project in projects) {
        for (int col = 0; col < columns.length; col++) {
          final field = columns[col];
          String value = '';
          
          switch (field) {
            case 'projectName':
              value = project['projectName']?.toString() ?? '';
              break;
            case 'projectRef':
              value = project['projectRef']?.toString() ?? '';
              break;
            case 'projectAddress':
              value = project['projectAddress']?.toString() ?? '';
              break;
            case 'totalTime':
              value = project['totalTime']?.toString() ?? '';
              break;
            case 'totalExpenses':
              value = '${project['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} CHF';
              break;
          }
          
          sheet.getRangeByIndex(currentRow, col + 1).setText(value);
          
          // Style project rows
          final cell = sheet.getRangeByIndex(currentRow, col + 1);
          cell.cellStyle.fontSize = 11;
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.all.color = '#000000';
        }
        
        currentRow++;
      }
      
      // Auto-fit columns
      for (int col = 1; col <= columns.length; col++) {
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
      ..download = 'client_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  /// Clean sheet name for Excel (remove invalid characters)
  static String _cleanSheetName(String name) {
    // Excel sheet names cannot contain: [ ] : * ? / \
    return name.replaceAll(RegExp(r'[\[\]:*?/\\]'), '_').substring(0, name.length > 31 ? 31 : name.length);
  }
}
