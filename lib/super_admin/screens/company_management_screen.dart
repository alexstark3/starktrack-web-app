import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../services/company_module_service.dart';
import 'add_company.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Available modules for assignment
  final List<String> _availableModules =
      CompanyModuleService.getAvailableModules();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() => _isLoading = true);

      final querySnapshot =
          await FirebaseFirestore.instance.collection('companies').get();

      final companies = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Handle modules field - could be Map or List
        List<String> modules = [];
        final modulesData = data['modules'];
        if (modulesData != null) {
          if (modulesData is List) {
            modules = List<String>.from(modulesData);
          } else if (modulesData is Map) {
            // Convert Map to List (keys are module names)
            modules = modulesData.keys.cast<String>().toList();
          }
        }

        // Find the company admin user
        String adminEmail = '';

        // Query users from the company's subcollection to find the admin
        try {
          final allUsersQuery = await FirebaseFirestore.instance
              .collection('companies')
              .doc(doc.id)
              .collection('users')
              .get();

          // Check each user's roles
          for (final userDoc in allUsersQuery.docs) {
            final userData = userDoc.data();
            final roles = List<String>.from(userData['roles'] ?? []);

            if (roles.contains('company_admin')) {
              final firstName = userData['firstName'] ?? '';
              final surname = userData['surname'] ?? '';
              final email = userData['email'] ?? '';

              // Format: "firstName Surname\nEmail: email"
              adminEmail = firstName.isNotEmpty && surname.isNotEmpty
                  ? '$firstName $surname\nEmail: $email'
                  : email;
              break;
            }
          }
        } catch (e) {
          debugPrint('❌ Error fetching admin for company ${doc.id}: $e');
        }

        // Count actual users in the company and update the company document
        int actualUserCount = 0;
        try {
          final usersQuery = await FirebaseFirestore.instance
              .collection('companies')
              .doc(doc.id)
              .collection('users')
              .get();
          actualUserCount = usersQuery.docs.length;

          // Update the company document with the real user count
          final storedUserCount = data['userCount'] ?? 0;
          if (actualUserCount != storedUserCount) {
            await FirebaseFirestore.instance
                .collection('companies')
                .doc(doc.id)
                .update({
              'userCount': actualUserCount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('❌ Error counting users for company ${doc.id}: $e');
        }

        companies.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Company',
          'email': data['email'] ?? '',
          'adminEmail': adminEmail,
          'modules': modules,
          'active': data['active'] ?? true,
          'userLimit': data['userLimit'] ?? 10, // Default user limit
          'userCount':
              actualUserCount, // Use actual count from users collection
          'createdAt': data['createdAt'],
          'address': data['address'], // Include the address field
        });
      }

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading companies: $e');
      setState(() => _isLoading = false);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading companies: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;

    return _companies.where((company) {
      final name = company['name'].toString().toLowerCase();
      final adminEmail = company['adminEmail'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || adminEmail.contains(query);
    }).toList();
  }

  Future<void> _updateCompanyModules(
      String companyId, List<String> modules) async {
    final success =
        await CompanyModuleService.updateCompanyModules(companyId, modules);

    if (success) {
      // Update local state
      setState(() {
        final companyIndex = _companies.indexWhere((c) => c['id'] == companyId);
        if (companyIndex != -1) {
          _companies[companyIndex]['modules'] = modules;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company modules updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating modules'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCompanyStatus(String companyId, bool active) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        final companyIndex = _companies.indexWhere((c) => c['id'] == companyId);
        if (companyIndex != -1) {
          _companies[companyIndex]['active'] = active;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Company ${active ? 'activated' : 'deactivated'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating company status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserLimit(String companyId, int userLimit) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'userLimit': userLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        final companyIndex = _companies.indexWhere((c) => c['id'] == companyId);
        if (companyIndex != -1) {
          _companies[companyIndex]['userLimit'] = userLimit;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User limit updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating user limit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user limit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editCompany(Map<String, dynamic> company) async {
    // Show edit dialog with current company data using the same AddCompanyDialog
    showDialog(
      context: context,
      builder: (context) => AddCompanyDialog(
        onCompanyAdded: _loadCompanies,
        existingCompany: company, // Pass existing company data
      ),
    );
  }

  Future<void> _deleteCompany(String companyId, String companyName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
            'Are you sure you want to delete "$companyName"?\n\nThis action cannot be undone and will delete ALL associated data including:\n• Company and all users\n• All time logs and sessions\n• All projects and clients\n• All holiday and time-off policies\n• All historical data'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      // Step 1: Get all users in the company
      final usersQuery = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .get();

      final userIds = usersQuery.docs.map((doc) => doc.id).toList();

      // Step 2: Delete all time logs for all users
      if (userIds.isNotEmpty) {
        final timeLogsQuery = await FirebaseFirestore.instance
            .collection('timeLogs')
            .where('userId', whereIn: userIds)
            .get();

        final timeLogsBatch = FirebaseFirestore.instance.batch();
        for (final doc in timeLogsQuery.docs) {
          timeLogsBatch.delete(doc.reference);
        }
        await timeLogsBatch.commit();
      }

      // Step 3: Delete all projects for this company
      final projectsQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('companyId', isEqualTo: companyId)
          .get();

      final projectsBatch = FirebaseFirestore.instance.batch();
      for (final doc in projectsQuery.docs) {
        projectsBatch.delete(doc.reference);
      }
      await projectsBatch.commit();

      // Step 4: Delete all clients for this company
      final clientsQuery = await FirebaseFirestore.instance
          .collection('clients')
          .where('companyId', isEqualTo: companyId)
          .get();

      final clientsBatch = FirebaseFirestore.instance.batch();
      for (final doc in clientsQuery.docs) {
        clientsBatch.delete(doc.reference);
      }
      await clientsBatch.commit();

      // Step 5: Delete all holiday policies for this company
      final holidayPoliciesQuery = await FirebaseFirestore.instance
          .collection('holidayPolicies')
          .where('companyId', isEqualTo: companyId)
          .get();

      final holidayBatch = FirebaseFirestore.instance.batch();
      for (final doc in holidayPoliciesQuery.docs) {
        holidayBatch.delete(doc.reference);
      }
      await holidayBatch.commit();

      // Step 6: Delete all time-off policies for this company
      final timeOffPoliciesQuery = await FirebaseFirestore.instance
          .collection('timeOffPolicies')
          .where('companyId', isEqualTo: companyId)
          .get();

      final timeOffBatch = FirebaseFirestore.instance.batch();
      for (final doc in timeOffPoliciesQuery.docs) {
        timeOffBatch.delete(doc.reference);
      }
      await timeOffBatch.commit();

      // Step 7: Delete all users in the company
      final usersBatch = FirebaseFirestore.instance.batch();
      for (final userDoc in usersQuery.docs) {
        usersBatch.delete(userDoc.reference);
      }
      await usersBatch.commit();

      // Step 8: Finally delete the company document
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .delete();

      // Update local state
      setState(() {
        _companies.removeWhere((c) => c['id'] == companyId);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Company "$companyName" and ALL associated data deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting company: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModuleAssignmentDialog(Map<String, dynamic> company) {
    List<String> selectedModules = List.from(company['modules']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign Modules - ${company['name']}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select modules for this company:'),
                const SizedBox(height: 16),
                ...(_availableModules.map((module) => CheckboxListTile(
                      title: Text(_getModuleDisplayName(module)),
                      subtitle: Text(_getModuleDescription(module)),
                      value: selectedModules.contains(module),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedModules.add(module);
                          } else {
                            selectedModules.remove(module);
                          }
                        });
                      },
                    ))),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateCompanyModules(company['id'], selectedModules);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserLimitDialog(Map<String, dynamic> company) {
    final currentLimit = company['userLimit'] ?? 10;
    final currentUsers = company['userCount'] ?? 0;
    final controller = TextEditingController(text: currentLimit.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set User Limit - ${company['name']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current users: $currentUsers'),
              const SizedBox(height: 16),
              Text('Set maximum number of users:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Limit',
                  hintText: 'Enter maximum number of users',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Warning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Setting a limit lower than current users ($currentUsers) may prevent new user registrations.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = int.tryParse(controller.text) ?? currentLimit;
              Navigator.of(context).pop();
              _updateUserLimit(company['id'], newLimit);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getModuleDisplayName(String module) {
    return CompanyModuleService.getModuleDisplayName(module);
  }

  String _getModuleDescription(String module) {
    return CompanyModuleService.getModuleDescription(module);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    if (colors == null) {
      return const Scaffold(
        body: Center(child: Text('Theme error: AppColors not found')),
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundDark,
      appBar: AppBar(
        title: const Text('Company Management'),
        backgroundColor: colors.cardColorDark,
        foregroundColor: colors.textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanies,
            tooltip: 'Refresh companies',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search companies...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: colors.cardColorDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Company'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          foregroundColor: colors.whiteTextOnBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddCompanyDialog(
                              onCompanyAdded: _loadCompanies,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Company List
                Expanded(
                  child: ListView.builder(
                    key: ValueKey('companies_management_list_$_searchQuery'),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredCompanies.length,
                    itemBuilder: (context, index) {
                      final company = _filteredCompanies[index];
                      return _buildCompanyCard(company, colors);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, AppColors colors) {
    final modules = List<String>.from(company['modules']);
    final isActive = company['active'] ?? true;
    final userCount = company['userCount'] ?? 0;
    final userLimit = company['userLimit'] ?? 10;
    final isOverLimit = userCount > userLimit;

    return Card(
      color: colors.cardColorDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Company Admin: ${company['adminEmail'] ?? 'Not set'}',
                  style: TextStyle(
                    color: colors.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Status Toggle
                Row(
                  children: [
                    Text(
                      'Active:',
                      style: TextStyle(
                        color: colors.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isActive,
                      onChanged: (value) =>
                          _toggleCompanyStatus(company['id'], value),
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action Buttons under the active toggle
                Row(
                  children: [
                    // Edit Button
                    IconButton(
                      onPressed: () => _editCompany(company),
                      icon: Icon(
                        Icons.edit,
                        color: colors.primaryBlue,
                        size: 20,
                      ),
                      tooltip: 'Edit Company',
                    ),
                    // Delete Button
                    IconButton(
                      onPressed: () =>
                          _deleteCompany(company['id'], company['name']),
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Delete Company',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Company Info
            Row(
              children: [
                Icon(Icons.people, color: colors.primaryBlue, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$userCount/$userLimit users',
                  style: TextStyle(
                    color: isOverLimit ? Colors.red : colors.textColor,
                    fontWeight:
                        isOverLimit ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isOverLimit) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.warning, color: Colors.red, size: 16),
                ],
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, color: colors.primaryBlue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Created: ${company['createdAt'] != null ? _formatDate(company['createdAt']) : 'Unknown'}',
                  style: TextStyle(color: colors.textColor),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 16),

            // Modules Section
            Text(
              'Assigned Modules:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),

            if (modules.isEmpty)
              Text(
                'No modules assigned',
                style: TextStyle(
                  color: colors.textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: modules
                    .map((module) => Chip(
                          label: Text(_getModuleDisplayName(module)),
                          backgroundColor:
                              colors.primaryBlue.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: colors.primaryBlue),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Assign Modules'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showModuleAssignmentDialog(company),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('Set User Limit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showUserLimitDialog(company),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }
}
