import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../security/company_migration_service.dart';
import '../../theme/app_colors.dart';

class CompanyMigrationTool extends StatefulWidget {
  const CompanyMigrationTool({Key? key}) : super(key: key);

  @override
  State<CompanyMigrationTool> createState() => _CompanyMigrationToolState();
}

class _CompanyMigrationToolState extends State<CompanyMigrationTool> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all companies from Firestore
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();
      
      final companies = <Map<String, dynamic>>[];
      
      for (final doc in companiesSnapshot.docs) {
        final companyData = doc.data();
        // Only include companies that do NOT have a secureId
        final isMigrated = companyData.containsKey('secureId');
        if (isMigrated) continue;
        companies.add({
          'id': doc.id,
          'name': companyData['name'] ?? 'Unknown',
          'isMigrated': isMigrated,
          'newCompanyId': null,
        });
      }
      
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading companies: $e')),
        );
      }
    }
  }

  Future<void> _migrateCompany(String companyId) async {
    setState(() => _isMigrating = true);
    
    try {
      final result = await CompanyMigrationService.migrateCompany(companyId);
      
      if (mounted) {
        final success = result['status'] == 'success';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Company migrated successfully!' 
              : 'Migration failed: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          _loadCompanies(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  Future<void> _migrateAllCompanies() async {
    setState(() => _isMigrating = true);
    
    try {
      final results = await CompanyMigrationService.migrateAllCompanies();
      
      if (mounted) {
        final successCount = results.where((r) => r['status'] == 'success').length;
        final failureCount = results.length - successCount;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration complete: $successCount successful, $failureCount failed'),
            backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
          ),
        );
        
        _loadCompanies(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    // final l10n = AppLocalizations.of(context)!; // Remove unused variable

    return Scaffold(
      backgroundColor: colors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Company Migration Tool',
          style: TextStyle(color: colors.textColor),
        ),
        backgroundColor: colors.cardColorDark,
        actions: [
          if (!_isMigrating)
            IconButton(
              icon: Icon(Icons.refresh, color: colors.textColor),
              onPressed: _loadCompanies,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    color: colors.cardColorDark,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Migration Tool',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Migrate companies to secure IDs with random codes',
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.security, color: colors.whiteTextOnBlue),
                                  label: Text('Migrate All Companies',
                                      style: TextStyle(color: colors.whiteTextOnBlue)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    disabledBackgroundColor: colors.darkGray,
                                  ),
                                  onPressed: _isMigrating ? null : _migrateAllCompanies,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Companies List
                  Text(
                    'Companies (${_companies.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _companies.length,
                      itemBuilder: (context, index) {
                        final company = _companies[index];
                        final companyId = company['id'] as String;
                        final companyName = company['name'] as String? ?? 'Unknown';
                        final isMigrated = company['isMigrated'] as bool? ?? false;
                        final newCompanyId = company['newCompanyId'] as String?;

                        return Card(
                          color: colors.cardColorDark,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              companyName,
                              style: TextStyle(
                                color: colors.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Old ID: $companyId',
                                  style: TextStyle(color: colors.textColor.withOpacity(0.7)),
                                ),
                                if (newCompanyId != null)
                                  Text(
                                    'New ID: $newCompanyId',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMigrated)
                                  Icon(Icons.check_circle, color: Colors.green, size: 24)
                                else
                                  Icon(Icons.pending, color: Colors.orange, size: 24),
                                const SizedBox(width: 8),
                                if (!isMigrated && !_isMigrating)
                                  ElevatedButton(
                                    onPressed: () => _migrateCompany(companyId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primaryBlue,
                                      foregroundColor: colors.whiteTextOnBlue,
                                    ),
                                    child: const Text('Migrate'),
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
} 