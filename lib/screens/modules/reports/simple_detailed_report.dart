import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import 'user_excel_export.dart';
import 'project_excel_export.dart';
import 'client_excel_export.dart';
import 'user_report.dart';
import 'project_report.dart';
import 'client_report.dart';

class SimpleDetailedReport extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> reportConfig;

  const SimpleDetailedReport({
    super.key,
    required this.companyId,
    required this.reportConfig,
  });

  @override
  State<SimpleDetailedReport> createState() => _SimpleDetailedReportState();
}

class _SimpleDetailedReportState extends State<SimpleDetailedReport> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _reportData = [];
  Map<String, Map<String, dynamic>> _userReportData = {};
  Map<String, Map<String, dynamic>> _projectReportData = {};
  Map<String, Map<String, dynamic>> _clientReportData = {};
  bool _isLoading = true;
  TabController? _tabController;
  TabController? _projectTabController;
  TabController? _clientTabController;


  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _projectTabController?.dispose();
    _clientTabController?.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    
    try {
      final orientation = widget.reportConfig['orientation'] as String? ?? 'time';
      
      switch (orientation) {
        case 'project':
          await _generateProjectReport();
          // Initialize tab controller for project reports if multiple projects
          if (_projectReportData.length > 1) {
            _projectTabController?.dispose();
            _projectTabController = TabController(
              length: _projectReportData.length,
              vsync: this,
            );
            _projectTabController!.addListener(() {
              if (!_projectTabController!.indexIsChanging) {
                setState(() {
                  // Tab changed, rebuild UI
                });
              }
            });
          }
          break;
        case 'user':
          await _generateUserReport();
          // Initialize tab controller for user reports if multiple users
          if (_userReportData.length > 1) {
            _tabController?.dispose();
            _tabController = TabController(
              length: _userReportData.length,
              vsync: this,
            );
            _tabController!.addListener(() {
              if (!_tabController!.indexIsChanging) {
                setState(() {
                  // Tab changed, rebuild UI
                });
              }
            });
          }
          break;
        case 'client':
          await _generateClientReport();
          // Initialize tab controller for client reports if multiple clients
          if (_clientReportData.length > 1) {
            _clientTabController?.dispose();
            _clientTabController = TabController(
              length: _clientReportData.length,
              vsync: this,
            );
            _clientTabController!.addListener(() {
              if (!_clientTabController!.indexIsChanging) {
                setState(() {
                  // Tab changed, rebuild UI
                });
              }
            });
          }
          break;
        default:
          await _generateTimeReport();
      }
    } catch (e) {
      // Error generating report
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateProjectReport() async {
    final projectReport = ProjectReport(
      companyId: widget.companyId,
      reportConfig: widget.reportConfig,
    );
    
    await projectReport.generateReport();
    _projectReportData = projectReport.projectReportData;
    
    // Convert to flat list for backward compatibility
    _reportData = _projectReportData.values
        .expand((projectData) => projectData['sessions'] as List<Map<String, dynamic>>)
        .toList();
  }

  Future<void> _generateUserReport() async {
    final userReport = UserReport(
      companyId: widget.companyId,
      reportConfig: widget.reportConfig,
    );
    
    await userReport.generateReport();
    _userReportData = userReport.userReportData;
    
    if (_userReportData.isEmpty) {
      _reportData = [];
      return;
    }
    
    // Convert to flat list for backward compatibility
    _reportData = _userReportData.values
        .expand((userData) {
          final sessions = userData['sessions'] as List<Map<String, dynamic>>? ?? [];
          return sessions;
        })
        .toList();
  }

  Future<void> _generateClientReport() async {
    // Generate client report using the new ClientReport class
    final clientReport = ClientReport(
      companyId: widget.companyId,
      reportConfig: widget.reportConfig,
    );
    
    await clientReport.generateReport();
    _clientReportData = clientReport.clientReportData;
    
    // For backward compatibility, also set _reportData
    if (_clientReportData.isNotEmpty) {
      final firstClient = _clientReportData.values.first;
      final projects = firstClient['projects'] as List<Map<String, dynamic>>;
      final allSessions = <Map<String, dynamic>>[];
      
      for (final project in projects) {
        final sessions = project['sessions'] as List<Map<String, dynamic>>;
        allSessions.addAll(sessions);
      }
      
      _reportData = allSessions;
    }
  }

  Future<void> _generateTimeReport() async {
    // Similar to user report but for all users
    await _generateUserReport();
  }

  void _exportToExcel() {
    final orientation = widget.reportConfig['orientation'] as String? ?? 'time';
    
    // Exporting report
    
    // For user reports (single or multiple), create single Excel file with multiple sheets
    if (orientation == 'user') {
      // Exporting user report (single or multiple)
      
      try {
        UserExcelExportService.exportExcelWithMultipleSheets(_userReportData, widget.reportConfig);
        // Excel export completed successfully
        final sheetCount = _userReportData.length;
        final message = sheetCount > 1 
            ? 'Excel file with multiple user sheets exported successfully!'
            : 'Excel file exported successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Error during Excel export
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } else if (orientation == 'project') {
      // Exporting project report (single or multiple)
      
      try {
        ProjectExcelExportService.exportExcelWithMultipleProjectSheets(_projectReportData, widget.reportConfig);
        // Excel export completed successfully
        final sheetCount = _projectReportData.length;
        final message = sheetCount > 1 
            ? 'Excel file with multiple project sheets exported successfully!'
            : 'Excel file exported successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Error during Excel export
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } else if (orientation == 'client') {
      // Exporting client report (single or multiple)
      
      try {
        ClientExcelExportService.exportExcelWithMultipleClientSheets(_clientReportData, widget.reportConfig);
        // Excel export completed successfully
        final sheetCount = _clientReportData.length;
        final message = sheetCount > 1 
            ? 'Excel file with multiple client sheets exported successfully!'
            : 'Excel file exported successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Error during Excel export
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } else {
      // Exporting single report (user or time)
      UserExcelExportService.exportSingleReport(_reportData, widget.reportConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reportConfig['name']?.toString() ?? 'Detailed Report',
                        style: TextStyle(
                          fontSize: 18,
                          color: colors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Detailed Session Report',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      // Add date range information
                      if (widget.reportConfig['dateRange'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getDateRangeText(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: _exportToExcel,
                        icon: const Icon(Icons.file_download, size: 20),
                        label: const Text('Export Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: colors.whiteTextOnBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
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
                  : _reportData.isEmpty
                      ?                         Center(
                          child: Text(
                            'No data available for this report',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      : _buildReportContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(AppColors colors) {
    final orientation = widget.reportConfig['orientation'] as String? ?? 'time';
    
    // For user reports (single or multiple), show proper user content
    if (orientation == 'user' && _userReportData.isNotEmpty) {
      // If multiple users, show tabs
      if (_userReportData.length > 1 && _tabController != null) {
        return Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colors.primaryBlue,
              unselectedLabelColor: colors.textColor.withValues(alpha: 0.7),
              indicatorColor: colors.primaryBlue,
              tabs: _userReportData.values.map((userData) {
                final userName = userData['userName'] as String;
                final totalTime = userData['totalTime'] as String;
                final totalSessions = userData['totalSessions'] as int;
                
                return Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalSessions sessions • $totalTime',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _userReportData.values.map((userData) {
                  final sessions = userData['sessions'] as List<Map<String, dynamic>>;
                  return _buildUserTabContent(userData, sessions, colors);
                }).toList(),
              ),
            ),
          ],
        );
      } else {
        // Single user - show user content without tabs
        final userData = _userReportData.values.first;
        final sessions = userData['sessions'] as List<Map<String, dynamic>>;
        return _buildUserTabContent(userData, sessions, colors);
      }
    } else if (orientation == 'project' && _projectReportData.isNotEmpty) {
      // If multiple projects, show tabs
      if (_projectReportData.length > 1 && _projectTabController != null) {
        return Column(
          children: [
            // Tab bar
            TabBar(
              controller: _projectTabController,
              isScrollable: true,
              labelColor: colors.primaryBlue,
              unselectedLabelColor: colors.textColor.withValues(alpha: 0.7),
              indicatorColor: colors.primaryBlue,
              tabs: _projectReportData.values.map((projectData) {
                final projectName = projectData['projectName'] as String;
                final totalSessions = projectData['totalSessions'] as int;
                final totalTime = projectData['totalTime'] as String;
                
                return Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        projectName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalSessions sessions • $totalTime',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _projectTabController,
                children: _projectReportData.values.map((projectData) {
                  final sessions = projectData['sessions'] as List<Map<String, dynamic>>;
                  return _buildProjectTabContent(projectData, sessions, colors);
                }).toList(),
              ),
            ),
          ],
        );
      } else {
        // Single project - show project content without tabs
        final projectData = _projectReportData.values.first;
        final sessions = projectData['sessions'] as List<Map<String, dynamic>>;
        return _buildProjectTabContent(projectData, sessions, colors);
      }
          } else if (orientation == 'client' && _clientReportData.isNotEmpty) {
        // If multiple clients, show tabs
        if (_clientReportData.length > 1 && _clientTabController != null) {
          return Column(
            children: [
              // Tab bar
              TabBar(
                controller: _clientTabController,
                isScrollable: true,
                labelColor: colors.primaryBlue,
                unselectedLabelColor: colors.textColor.withValues(alpha: 0.7),
                indicatorColor: colors.primaryBlue,
                tabs: _clientReportData.values.map((clientData) {
                  final clientName = clientData['clientName'] as String;
                  final totalProjects = clientData['totalProjects'] as int;
                  final totalTime = clientData['totalTime'] as String;
                  
                  return Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$totalProjects projects • $totalTime',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _clientTabController,
                  children: _clientReportData.values.map((clientData) {
                    final projects = clientData['projects'] as List<Map<String, dynamic>>;
                    return _buildClientTabContent(clientData, projects, colors);
                  }).toList(),
                ),
              ),
            ],
          );
        } else {
          // Single client - show client content without tabs
          final clientData = _clientReportData.values.first;
          final projects = clientData['projects'] as List<Map<String, dynamic>>;
          return _buildClientTabContent(clientData, projects, colors);
        }
      } else {
        // For single user/project or other report types, show normal table
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildDataTable(colors),
          ),
        );
      }
  }

  Widget _buildUserTabContent(Map<String, dynamic> userData, List<Map<String, dynamic>> sessions, AppColors colors) {
    final groupedSessions = userData['groupedSessions'] as Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>?;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['userName'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSummaryItem('Sessions', '${userData['totalSessions']}', colors),
                          const SizedBox(width: 24),
                          _buildSummaryItem('Total Time', userData['totalTime'] as String, colors),
                          const SizedBox(width: 24),
                          _buildSummaryItem('Overtime Balance', userData['totalOvertime'] as String, colors),
                          const SizedBox(width: 24),
                          _buildSummaryItem('Expenses', userData['totalExpenses'] > 0 ? '${userData['totalExpenses']?.toStringAsFixed(2)}' : '0.00', colors),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSummaryItem('Vacation Balance', userData['vacationBalance']?.toString() ?? '0.0', colors),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Grouped sessions
          if (groupedSessions != null && groupedSessions.isNotEmpty)
            _buildGroupedSessionsView(groupedSessions, colors)
          else if (sessions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildUserSessionsTable(sessions, colors),
            )
          else
            Center(
              child: Text(
                'No sessions found for this user in the selected period',
                style: TextStyle(color: colors.textColor.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectTabContent(Map<String, dynamic> projectData, List<Map<String, dynamic>> sessions, AppColors colors) {
    final groupedSessions = projectData['groupedSessions'] as Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>?;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectData['projectName'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                if (projectData['projectRef'] != null && (projectData['projectRef'] as String).isNotEmpty)
                  Row(
                    children: [
                      Text('Ref: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                      Text(projectData['projectRef'] as String, style: TextStyle(color: colors.textColor)),
                    ],
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text('Address: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                      Expanded(child: Text(projectData['projectAddress']?.toString() ?? 'Not specified', style: TextStyle(color: colors.textColor))),
                    ],
                  ),
                ),

                // Client information if selected
                if ((widget.reportConfig['fields']?.contains('client') == true || 
                     widget.reportConfig['fieldsToInclude']?.contains('client') == true) && 
                    projectData['clientName'] != null && (projectData['clientName'] as String).isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Client name: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                            Text(projectData['clientName'] as String, style: TextStyle(color: colors.textColor)),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('Address: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                              Expanded(child: Text(projectData['clientAddress']?.toString() ?? 'Not specified', style: TextStyle(color: colors.textColor))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('Contact: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                              Text(projectData['clientContact']?.toString() ?? 'Not specified', style: TextStyle(color: colors.textColor)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('Email: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                              Text(projectData['clientEmail']?.toString() ?? 'Not specified', style: TextStyle(color: colors.textColor)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('Phone: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textColor)),
                              Text(projectData['clientPhone']?.toString() ?? 'Not specified', style: TextStyle(color: colors.textColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Project summary - dynamic based on selected fields
          if (_shouldShowSummarySection())
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: _buildDynamicSummaryItems(projectData, colors),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Grouped sessions
          if (groupedSessions != null && groupedSessions.isNotEmpty)
            _buildGroupedSessionsView(groupedSessions, colors)
          else if (sessions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildProjectSessionsTable(sessions, colors),
            )
          else
            Center(
              child: Text(
                'No sessions found for this project in the selected period',
                style: TextStyle(color: colors.textColor.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientTabContent(Map<String, dynamic> clientData, List<Map<String, dynamic>> projects, AppColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientData['clientName'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSummaryItem('Total Projects', '${clientData['totalProjects']}', colors),
                    const SizedBox(width: 24),
                    _buildSummaryItem('Total Time', clientData['totalTime'] as String, colors),
                    const SizedBox(width: 24),
                    _buildSummaryItem('Total Expenses', clientData['totalExpenses'] > 0 ? '${clientData['totalExpenses']?.toStringAsFixed(2)}' : '0.00', colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Projects table
          if (projects.isNotEmpty)
            _buildClientProjectsTable(projects, colors)
          else
            Center(
              child: Text(
                'No projects found for this client in the selected period',
                style: TextStyle(color: colors.textColor.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowSummarySection() {
    final selectedFields = (widget.reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];
    return selectedFields.contains('totalSessions') || 
           selectedFields.contains('totalTime') || 
           selectedFields.contains('totalExpenses');
  }

  List<Widget> _buildDynamicSummaryItems(Map<String, dynamic> projectData, AppColors colors) {
    final selectedFields = (widget.reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<Widget> items = [];
    
    if (selectedFields.contains('totalSessions')) {
      items.add(_buildSummaryItem('Sessions', '${projectData['totalSessions']}', colors));
      if (items.length > 1) items.add(const SizedBox(width: 24));
    }
    
    if (selectedFields.contains('totalTime')) {
      items.add(_buildSummaryItem('Total Time', projectData['totalTime'] as String, colors));
      if (items.length > 1) items.add(const SizedBox(width: 24));
    }
    
    if (selectedFields.contains('totalExpenses')) {
      items.add(_buildSummaryItem('Expenses', projectData['totalExpenses'] > 0 ? '${projectData['totalExpenses']?.toStringAsFixed(2)}' : '0.00', colors));
      if (items.length > 1) items.add(const SizedBox(width: 24));
    }
    
    // Remove the last spacer if there are items
    if (items.isNotEmpty && items.last is SizedBox) {
      items.removeLast();
    }
    
    return items;
  }

  String _getDateRangeText() {
    final dateRange = widget.reportConfig['dateRange'] as Map<String, dynamic>?;
    if (dateRange == null) return '';
    
    final startDate = (dateRange['startDate'] as Timestamp?)?.toDate();
    final endDate = (dateRange['endDate'] as Timestamp?)?.toDate();
    
    if (startDate != null && endDate != null) {
      return 'Report range: ${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}';
    }
    return '';
  }

  Widget _buildSummaryItem(String label, String value, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildClientProjectsTable(List<Map<String, dynamic>> projects, AppColors colors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADERS SECTION - Medium blue background with TOP rounded corners
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Project Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))),
                Expanded(flex: 2, child: Text('Reference', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))),
                Expanded(flex: 3, child: Text('Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))),
                Expanded(flex: 2, child: Text('Total Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))),
                Expanded(flex: 2, child: Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))),
              ],
            ),
          ),
          
          // PROJECTS SECTION - Light background, NO individual cards
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: projects.map((project) => _buildClientProjectRow(project, colors)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientProjectRow(Map<String, dynamic> project, AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: colors.primaryBlue.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(project['projectName']?.toString() ?? '', style: TextStyle(color: colors.textColor))),
          Expanded(flex: 2, child: Text(project['projectRef']?.toString() ?? '', style: TextStyle(color: colors.textColor))),
          Expanded(flex: 3, child: Text(project['projectAddress']?.toString() ?? '', style: TextStyle(color: colors.textColor))),
          Expanded(flex: 2, child: Text(project['totalTime']?.toString() ?? '', style: TextStyle(color: colors.textColor))),
          Expanded(flex: 2, child: Text('${project['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} CHF', style: TextStyle(color: colors.textColor))),
        ],
      ),
    );
  }

  Widget _buildDynamicHeaders(AppColors colors) {
    final selectedFields = (widget.reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];
    final orientation = widget.reportConfig['orientation'] as String? ?? 'time';
    
    final List<Widget> headerWidgets = [];
    
    if (selectedFields.contains('start') && selectedFields.contains('end')) {
      headerWidgets.add(Expanded(flex: 2, child: Text('Start - End', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    } else if (selectedFields.contains('start')) {
      headerWidgets.add(Expanded(flex: 1, child: Text('Start', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    } else if (selectedFields.contains('end')) {
      headerWidgets.add(Expanded(flex: 1, child: Text('End', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    }
    
    if (selectedFields.contains('duration')) {
      headerWidgets.add(Expanded(flex: 1, child: Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    }
    
    // Handle different field names for different report types
    if (orientation == 'project' && selectedFields.contains('worker')) {
      headerWidgets.add(Expanded(flex: 2, child: Text('Worker', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    } else if (orientation == 'user' && selectedFields.contains('project')) {
      headerWidgets.add(Expanded(flex: 2, child: Text('Project', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    }
    
    if (selectedFields.contains('expenses')) {
      headerWidgets.add(Expanded(flex: 1, child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    }
    
    if (selectedFields.contains('note')) {
      headerWidgets.add(Expanded(flex: 2, child: Text('Note', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.primaryBlue))));
    }
    
    return Row(children: headerWidgets);
  }

  Widget _buildDynamicSessionRow(Map<String, dynamic> session, AppColors colors, List<String> selectedFields, String orientation, String expenses, bool hasMultipleExpenses) {
    final List<Widget> rowWidgets = [];
    
    if (selectedFields.contains('start') && selectedFields.contains('end')) {
      rowWidgets.add(Expanded(
        flex: 2,
        child: Text(
          '${session['Start'] ?? ''} - ${session['End'] ?? ''}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textColor,
          ),
        ),
      ));
    } else if (selectedFields.contains('start')) {
      rowWidgets.add(Expanded(
        flex: 1,
        child: Text(
          session['Start'] ?? '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textColor,
          ),
        ),
      ));
    } else if (selectedFields.contains('end')) {
      rowWidgets.add(Expanded(
        flex: 1,
        child: Text(
          session['End'] ?? '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textColor,
          ),
        ),
      ));
    }
    
    if (selectedFields.contains('duration')) {
      rowWidgets.add(Expanded(
        flex: 1,
        child: Text(
          session['Duration'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
      ));
    }
    
    // Handle different field names for different report types
    if (orientation == 'project' && selectedFields.contains('worker')) {
      rowWidgets.add(Expanded(
        flex: 2,
        child: Text(
          session['Worker'] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: colors.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));
    } else if (orientation == 'user' && selectedFields.contains('project')) {
      rowWidgets.add(Expanded(
        flex: 2,
        child: Text(
          session['Project'] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: colors.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));
    }
    
    if (selectedFields.contains('expenses')) {
      rowWidgets.add(Expanded(
        flex: 1,
        child: Text(
          hasMultipleExpenses ? expenses.split(',')[0].trim() : expenses,
          style: TextStyle(
            color: colors.textColor,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    
    if (selectedFields.contains('note')) {
      rowWidgets.add(Expanded(
        flex: 2,
        child: Text(
          session['Note'] ?? '',
          style: TextStyle(
            color: colors.textColor,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    
    return Row(children: rowWidgets);
  }

  Widget _buildDynamicExpenseRow(AppColors colors, List<String> selectedFields, String orientation, String expenses, int expenseIndex) {
    final List<Widget> rowWidgets = [];
    
    if (selectedFields.contains('start') && selectedFields.contains('end')) {
      rowWidgets.add(Expanded(flex: 2, child: SizedBox()));
    } else if (selectedFields.contains('start') || selectedFields.contains('end')) {
      rowWidgets.add(Expanded(flex: 1, child: SizedBox()));
    }
    
    if (selectedFields.contains('duration')) {
      rowWidgets.add(Expanded(flex: 1, child: SizedBox()));
    }
    
    // Handle different field names for different report types
    if (orientation == 'project' && selectedFields.contains('worker')) {
      rowWidgets.add(Expanded(flex: 2, child: SizedBox()));
    } else if (orientation == 'user' && selectedFields.contains('project')) {
      rowWidgets.add(Expanded(flex: 2, child: SizedBox()));
    }
    
    // Additional expense
    rowWidgets.add(Expanded(
      flex: 1,
      child: Text(
        expenses.split(',')[expenseIndex].trim(),
        style: TextStyle(
          color: colors.textColor,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ));
    
    if (selectedFields.contains('note')) {
      rowWidgets.add(Expanded(flex: 2, child: SizedBox()));
    }
    
    return Row(children: rowWidgets);
  }

  Widget _buildGroupedSessionsView(
      Map<String, Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>> groupedSessions, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedSessions.values.first.entries.map((monthEntry) {
        final month = monthEntry.key;
        final weeks = monthEntry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Weeks
            ...weeks.entries.map((weekEntry) {
              final week = weekEntry.key;
              final days = weekEntry.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      week,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Days for this week
                  ...days.entries.map((dayEntry) {
                    final day = dayEntry.key;
                    final sessions = dayEntry.value;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UNIFIED DAY CARD - Date + Headers + Sessions in ONE card - SAME SIZE AS WEEK
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.primaryBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. DATE SECTION - Darker blue
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colors.primaryBlue.withValues(alpha: 0.15),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Show daily overtime after the date
                                    if (sessions.isNotEmpty && sessions.first['Overtime']?.toString().isNotEmpty == true)
                                      Row(
                                        children: [
                                          Text(
                                            'Overtime: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: colors.primaryBlue,
                                            ),
                                          ),
                                          Text(
                                            sessions.first['Overtime'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: sessions.first['Overtime'].toString().startsWith('+') 
                                                  ? Colors.green 
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              
                              // 2. HEADERS SECTION - Medium blue
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colors.primaryBlue.withValues(alpha: 0.1),
                                ),
                                child: _buildDynamicHeaders(colors),
                              ),
                              
                              // 3. SESSIONS SECTION - Light blue (inherits from parent)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: sessions.map((session) => _buildSessionRowInline(session, colors)).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }



  Widget _buildSessionRowInline(Map<String, dynamic> session, AppColors colors) {
    final selectedFields = (widget.reportConfig['fields'] as List<dynamic>?)?.cast<String>() ?? [];
    final orientation = widget.reportConfig['orientation'] as String? ?? 'time';
    final expenses = session['Expenses']?.toString() ?? '';
    final hasMultipleExpenses = expenses.isNotEmpty && expenses.contains(',');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main session row
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          child: _buildDynamicSessionRow(session, colors, selectedFields, orientation, expenses, hasMultipleExpenses),
        ),
        
        // Additional expense rows (if multiple expenses)
        if (hasMultipleExpenses && selectedFields.contains('expenses')) ...[
          for (int i = 1; i < expenses.split(',').length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: _buildDynamicExpenseRow(colors, selectedFields, orientation, expenses, i),
            ),
        ],
      ],
    );
  }

  Widget _buildUserSessionsTable(List<Map<String, dynamic>> sessions, AppColors colors) {
    if (sessions.isEmpty) return const SizedBox();
    
    // Headers that match the actual data structure
    final headers = ['Date', 'Start - End', 'Duration', 'Project', 'Expenses', 'Note'];
    
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(colors.primaryBlue.withValues(alpha: 0.1)),
      columns: headers.map((header) => DataColumn(
        label: Text(
          header,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.primaryBlue,
          ),
        ),
      )).toList(),
      rows: sessions.map((session) => DataRow(
        cells: [
          // Date
          DataCell(Text(
            session['Date']?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          )),
          // Start - End
          DataCell(Text(
            '${session['Start'] ?? ''} - ${session['End'] ?? ''}',
            style: TextStyle(color: colors.textColor),
          )),
          // Duration
          DataCell(Text(
            session['Duration']?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          )),
          // Project
          DataCell(Text(
            session['Project']?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          )),
          // Expenses
          DataCell(Text(
            session['Expenses']?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          )),
          // Note
          DataCell(Text(
            session['Note']?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          )),
        ],
      )).toList(),
    );
  }

  Widget _buildProjectSessionsTable(List<Map<String, dynamic>> sessions, AppColors colors) {
    if (sessions.isEmpty) return const SizedBox();
    
    final headers = ['Date', 'Worker', 'Start', 'End', 'Duration', 'Note', 'Expenses'];
    
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(colors.primaryBlue.withValues(alpha: 0.1)),
      columns: headers.map((header) => DataColumn(
        label: Text(
          header,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.primaryBlue,
          ),
        ),
      )).toList(),
      rows: sessions.map((session) => DataRow(
        cells: headers.map((header) => DataCell(
          Text(
            session[header]?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          ),
        )).toList(),
      )).toList(),
    );
  }

  Widget _buildDataTable(AppColors colors) {
    if (_reportData.isEmpty) return const SizedBox();
    
    final headers = _reportData.first.keys.toList();
    
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(colors.primaryBlue.withValues(alpha: 0.1)),
      columns: headers.map((header) => DataColumn(
        label: Text(
          header,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.primaryBlue,
          ),
        ),
      )).toList(),
      rows: _reportData.map((row) => DataRow(
        cells: headers.map((header) => DataCell(
          Text(
            row[header]?.toString() ?? '',
            style: TextStyle(color: colors.textColor),
          ),
        )).toList(),
      )).toList(),
    );
  }
}
