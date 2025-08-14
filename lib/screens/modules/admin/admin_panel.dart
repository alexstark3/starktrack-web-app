import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../super_admin/services/company_module_service.dart';
import 'add_user.dart';
import 'holiday_policy/holiday_policy.dart';
import 'timeoff_policy/timeoff_policy.dart';
import '../../../../utils/app_logger.dart';
import '../../../widgets/app_search_field.dart';

class AdminPanel extends StatefulWidget {
  final String companyId;
  final List<String> currentUserRoles;

  const AdminPanel({
    super.key,
    required this.companyId,
    required this.currentUserRoles,
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _searchText = '';
  List<Map<String, dynamic>> _teamLeaders = [];

  bool get isSuperAdmin => widget.currentUserRoles.contains('super_admin');

  @override
  void initState() {
    super.initState();
    _fetchTeamLeaders();
  }

  Future<void> _fetchTeamLeaders() async {
    try {
      final res = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .where('roles', arrayContains: 'team_leader')
          .get();

      if (mounted) {
        setState(() {
          _teamLeaders = res.docs
              .map((d) => {
                    'id': d.id,
                    'firstName': d['firstName'] ?? '',
                    'surname': d['surname'] ?? '',
                  })
              .toList();
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching team leaders: $e');
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AddUserDialog(
        companyId: widget.companyId,
        teamLeaders: _teamLeaders,
        currentUserRoles: widget.currentUserRoles,
        onUserAdded: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showEditUserDialog(DocumentSnapshot userDoc) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AddUserDialog(
        companyId: widget.companyId,
        teamLeaders: _teamLeaders,
        editUser: userDoc,
        currentUserRoles: widget.currentUserRoles,
        onUserAdded: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showHolidayPolicyDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => HolidayPolicyListDialog(
        companyId: widget.companyId,
        onPolicyAdded: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showTimeOffPolicyDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => TimeOffPolicyListDialog(
        companyId: widget.companyId,
        onPolicyAdded: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: appColors.backgroundDark,
        title: Text(
          l10n.deleteUser,
          style: TextStyle(color: appColors.textColor),
        ),
        content: Text(
          l10n.deleteUserConfirmation,
          style: TextStyle(color: appColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel,
                style: TextStyle(color: appColors.primaryBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 1. Delete user's subcollections (sessions, all_logs, etc.)
        final userDoc = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userId);

        // Delete sessions subcollection
        final sessionsQuery = userDoc.collection('sessions');
        final sessionsSnapshot = await sessionsQuery.get();
        for (final sessionDoc in sessionsSnapshot.docs) {
          // Delete logs subcollection within each session
          final logsQuery = sessionDoc.reference.collection('logs');
          final logsSnapshot = await logsQuery.get();
          for (final logDoc in logsSnapshot.docs) {
            await logDoc.reference.delete();
          }
          await sessionDoc.reference.delete();
        }

        // Delete all_logs subcollection
        final allLogsQuery = userDoc.collection('all_logs');
        final allLogsSnapshot = await allLogsQuery.get();
        for (final logDoc in allLogsSnapshot.docs) {
          await logDoc.reference.delete();
        }

        // 2. Delete the user document from company
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userId)
            .delete();

        // 3. Delete userCompany mapping
        await FirebaseFirestore.instance
            .collection('userCompany')
            .doc(userId)
            .delete();

        // 4. Decrement user count
        await CompanyModuleService.decrementUserCount(widget.companyId);

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: appColors.backgroundDark,
      body: Column(
        children: [
          // Main card with search and action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? appColors.backgroundLight
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Border.all(color: Colors.black26, width: 1),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar and New User button row
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isVerySmall = screenWidth < 445;

                      if (isVerySmall) {
                        // Very small screens: stack search and button
                        return Column(
                          children: [
                            AppSearchField(
                              hintText: l10n.searchUsers,
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() => _searchText = value);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showAddUserDialog,
                                icon: Icon(Icons.add,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addNewUser,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Normal screens: search and New User button on same line
                        return Row(
                          children: [
                            Expanded(
                              child: AppSearchField(
                                hintText: l10n.searchUsers,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() => _searchText = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showAddUserDialog,
                                icon: Icon(Icons.add,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addNewUser,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Policy buttons row
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isVerySmall = screenWidth < 445;

                      if (isVerySmall) {
                        // Very small screens: stack policy buttons
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showHolidayPolicyDialog,
                                icon: Icon(Icons.calendar_today,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addHolidayPolicy,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showTimeOffPolicyDialog,
                                icon: Icon(Icons.schedule,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addTimeOffPolicy,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Normal screens: policy buttons in a wrap
                        return Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showHolidayPolicyDialog,
                                icon: Icon(Icons.calendar_today,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addHolidayPolicy,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: _showTimeOffPolicyDialog,
                                icon: Icon(Icons.schedule,
                                    color: appColors.whiteTextOnBlue),
                                label: Text(
                                  l10n.addTimeOffPolicy,
                                  style: TextStyle(
                                      color: appColors.whiteTextOnBlue),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryBlue,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: appColors.primaryBlue),
                  );
                }

                final users = snapshot.data?.docs ?? [];
                final filteredUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchLower = _searchText.toLowerCase();
                  return data['firstName']
                              ?.toString()
                              .toLowerCase()
                              .contains(searchLower) ==
                          true ||
                      data['surname']
                              ?.toString()
                              .toLowerCase()
                              .contains(searchLower) ==
                          true ||
                      data['email']
                              ?.toString()
                              .toLowerCase()
                              .contains(searchLower) ==
                          true;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      _searchText.isEmpty ? l10n.noUsers : l10n.noUsersFound,
                      style: TextStyle(color: appColors.darkGray),
                    ),
                  );
                }

                return ListView.builder(
                  key: ValueKey('admin_users_list_$_searchText'),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isProtectedUser =
                        data['roles']?.contains('super_admin') == true;

                    return Card(
                      key: ValueKey('admin_user_item_${doc.id}'),
                      color: appColors.backgroundLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${data['firstName'] ?? ''} ${data['surname'] ?? ''}',
                                        style: TextStyle(
                                          color: appColors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['email'] ?? '',
                                        style: TextStyle(
                                            color: appColors.darkGray),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Roles
                            Wrap(
                              spacing: 4,
                              children: [
                                ...(data['roles'] as List<dynamic>? ?? [])
                                    .map((role) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: appColors.primaryBlue
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      role.toString(),
                                      style: TextStyle(
                                        color: appColors.primaryBlue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            // Action buttons at bottom left
                            if (!isProtectedUser) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Active status indicator
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (data['active'] ?? true)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _showEditUserDialog(doc),
                                    icon: Icon(Icons.edit,
                                        color: appColors.primaryBlue),
                                    tooltip: l10n.editUser,
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteUser(doc.id),
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: l10n.deleteUser,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
