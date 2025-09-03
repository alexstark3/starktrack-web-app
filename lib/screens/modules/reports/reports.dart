import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

import 'report_builder_dialog.dart';

import 'simple_detailed_report.dart';

class ReportsScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  
  const ReportsScreen({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _savedReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  // Translate report name dynamically based on current language
  String _translateReportName(String storedName, AppLocalizations l10n) {
    // Check if the name starts with an orientation key
    final orientationMap = {
      'project': l10n.project,
      'worker': l10n.worker,
      'client': l10n.client,
    };
    
    for (final entry in orientationMap.entries) {
      if (storedName.startsWith('${entry.key} ')) {
        // Replace the orientation key with translated name and capitalize first letter
        final translatedName = storedName.replaceFirst('${entry.key} ', '${entry.value} ');
        return translatedName.isNotEmpty 
            ? translatedName[0].toUpperCase() + translatedName.substring(1)
            : translatedName;
      }
    }
    
    // If no orientation key found, return the original name with first letter capitalized
    return storedName.isNotEmpty 
        ? storedName[0].toUpperCase() + storedName.substring(1)
        : storedName;
  }

  Future<void> _loadSavedReports() async {
    try {
  
      
      // First try without orderBy to avoid index issues
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('reports')
          .where('createdBy', isEqualTo: widget.userId)
          .get();

      

      final reports = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort manually to avoid Firestore index requirement
      reports.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _savedReports = reports;
        _isLoading = false;
      });

              // Reports loaded successfully
      } catch (e) {
        // Error loading reports
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: ${e.toString()}'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showReportBuilder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReportBuilderDialog(
        companyId: widget.companyId,
        userId: widget.userId,
      ),
    );

    if (result != null) {
      _loadSavedReports(); // Refresh the list
    }
  }

  Future<void> _runReport(Map<String, dynamic> reportConfig) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDetailedReport(
        companyId: widget.companyId,
        reportConfig: reportConfig,
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      final reportRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('reports')
          .doc(reportId);

      // Step 1: Check for and delete any subcollections
      
      
      // Common subcollection names that might exist
      final subcollectionNames = ['data', 'results', 'cache', 'exports', 'history'];
      
      for (final subcollectionName in subcollectionNames) {
        final subcollectionRef = reportRef.collection(subcollectionName);
        final subcollectionSnapshot = await subcollectionRef.limit(1).get();
        
        if (subcollectionSnapshot.docs.isNotEmpty) {
          
          // Delete all documents in the subcollection
          final allDocs = await subcollectionRef.get();
          final batch = FirebaseFirestore.instance.batch();
          
          for (final doc in allDocs.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          
        }
      }
      
      // Step 2: Check for any related documents in other collections
      // (e.g., cached report data, export logs, etc.)
      final relatedCollections = ['report_cache', 'report_exports', 'report_logs'];
      
      for (final collectionName in relatedCollections) {
        final relatedQuery = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection(collectionName)
            .where('reportId', isEqualTo: reportId);
            
        final relatedDocs = await relatedQuery.get();
        
        if (relatedDocs.docs.isNotEmpty) {

          final batch = FirebaseFirestore.instance.batch();
          
          for (final doc in relatedDocs.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          
        }
      }
      
      // Step 3: Finally delete the main report document
      
      await reportRef.delete();
      
      _loadSavedReports();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.deleteSuccessful} (Complete cleanup performed)'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
          ),
        );
      }
      
      // Report completely deleted with all related data
      
    } catch (e) {
      // Error deleting report
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: $e'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.dashboardBackground,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search Bar and Create Report Button
            Row(
              children: [
                // Search Bar
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        constraints: const BoxConstraints.tightFor(height: 38),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        hintText: l10n.search,
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : colors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : colors.darkGray,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? colors.lightGray
                            : Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? colors.borderColorDark
                                : colors.borderColorLight,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? colors.borderColorDark
                                : colors.borderColorLight,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: colors.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : colors.textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Create Report Button
                SizedBox(
                  width: 120,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _showReportBuilder,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.createReport),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryBlue,
                      foregroundColor: colors.whiteTextOnBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(120, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Reports List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_savedReports.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 64,
                        color: colors.textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports found',
                        style: TextStyle(
                          fontSize: 18,
                          color: colors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first custom report or check console for errors',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textColor.withValues(alpha: 0.5),
                        ),
                      ),

                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _savedReports.length,
                  itemBuilder: (context, index) {
                    final report = _savedReports[index];
                    final createdAt = (report['createdAt'] as Timestamp).toDate();
                    final orientation = report['orientation'] ?? 'time';
                    final fields = List<String>.from(report['fields'] ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: colors.backgroundLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colors.borderColorDark
                              : colors.borderColorLight,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Report Title
                            Text(
                              _translateReportName(report['name'] ?? 'Unnamed Report', l10n),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Report Details
                            Text(
                              '${l10n.type}: ${_getOrientationLabel(orientation, l10n)}',
                              style: TextStyle(
                                color: colors.primaryBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              children: [
                                Text(
                                  '${l10n.fields}: ',
                                  style: TextStyle(
                                    color: colors.textColor.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                ..._getFieldLabels(fields, l10n).map((label) => Text(
                                  '$label, ',
                                  style: TextStyle(
                                    color: colors.textColor.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.created}: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                              style: TextStyle(
                                color: colors.textColor.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Action Buttons at Bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _runReport(report),
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: Text(l10n.view),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primaryBlue,
                                    foregroundColor: colors.whiteTextOnBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteReport(report['id']),
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: colors.error,
                                  tooltip: l10n.delete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrientationLabel(String orientation, AppLocalizations l10n) {
    switch (orientation) {
      case 'project':
        return l10n.project;
      case 'worker':
        return l10n.worker;
      case 'client':
        return l10n.client;
      default:
        return orientation.toUpperCase();
    }
  }

  List<String> _getFieldLabels(List<String> fields, AppLocalizations l10n) {
    return fields.map((field) {
      switch (field) {
        case 'client':
          return l10n.client;
        case 'totalHours':
          return l10n.totalHours;
        case 'totalExpenses':
          return l10n.totalExpenses;
        case 'projectCount':
          return l10n.totalProjects;
        case 'project':
          return l10n.project;
        case 'worker':
          return l10n.worker;
        case 'user':
          return l10n.worker;
        case 'date':
          return l10n.date;
        case 'start':
          return l10n.start;
        case 'end':
          return l10n.end;
        case 'duration':
          return l10n.duration;
        case 'expenses':
          return l10n.expenses;
        case 'note':
          return l10n.note;
        case 'userCount':
          return l10n.users;
        case 'avgHoursPerDay':
          return l10n.avgHoursPerDay;
        case 'dateRange':
          return l10n.dateRange;
        case 'status':
          return l10n.status;
        case 'projectName':
          return l10n.projectName;
        case 'projectRef':
          return l10n.projectRef;
        case 'projectAddress':
          return l10n.address;
        case 'totalTime':
          return l10n.totalTime;
        case 'totalOvertime':
          return l10n.totalOvertime;
        case 'timeOff':
          return l10n.vacationBalance;
        case 'overtime':
          return l10n.overtime;
        case 'timeoff':
          return l10n.vacationBalance;
        case 'totalSessions':
          return l10n.totalSessions;
        case 'sessions':
          return l10n.sessions;
        case 'sessionCount':
          return l10n.sessionCount;
        default:
          // Handle any remaining raw field names by cleaning them up
          String cleaned = field
              .replaceAll(RegExp(r'\$[0-9]+'), '') // Remove $1, $2, etc.
              .replaceAll(RegExp(r'([A-Z])'), ' \$1') // Add spaces before capitals
              .trim();
          return cleaned.isEmpty ? field : cleaned;
      }
    }).toList();
  }
}
