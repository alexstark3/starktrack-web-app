import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_user.dart';
import 'holiday_policy.dart';
import 'timeoff_policy.dart';

class AdminPanel extends StatefulWidget {
  final String companyId;
  final List<String> currentUserRoles;

  const AdminPanel({
    Key? key,
    required this.companyId,
    required this.currentUserRoles,
  }) : super(key: key);

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

      _teamLeaders = res.docs
          .map((d) => {
                'id': d.id,
                'firstName': d['firstName'] ?? '',
                'surname': d['surname'] ?? '',
              })
          .toList();
    } catch (e) {
      print('Error fetching team leaders: $e');
    } finally {
      setState(() {});
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        companyId: widget.companyId,
        teamLeaders: _teamLeaders,
        currentUserRoles: widget.currentUserRoles,
        onUserAdded: () {
          setState(() {});
        },
      ),
    );
  }

  void _showEditUserDialog(DocumentSnapshot userDoc) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        companyId: widget.companyId,
        teamLeaders: _teamLeaders,
        editUser: userDoc,
        currentUserRoles: widget.currentUserRoles,
        onUserAdded: () {
          setState(() {});
        },
      ),
    );
  }

  void _showHolidayPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => HolidayPolicyListDialog(
        companyId: widget.companyId,
        onPolicyAdded: () {
          setState(() {});
        },
      ),
    );
  }

  void _showTimeOffPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => TimeOffPolicyListDialog(
        companyId: widget.companyId,
        onPolicyAdded: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userId)
            .delete();

        // Delete from Firebase Auth
        // Note: This requires admin SDK, so we'll just delete from Firestore for now
        // The user will be unable to log in since their data is gone

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userDeleted)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
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
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black26,
                        width: 1,
                      ),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? appColors.lightGray
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchText = value),
                      decoration: InputDecoration(
                        hintText: l10n.searchUsers,
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFB3B3B3)
                              : appColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFB3B3B3)
                              : appColors.darkGray,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFCCCCCC)
                            : appColors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons row with responsive layout
                  Builder(
                    builder: (context) {
                      // Check if we have enough space for all buttons in a row
                      final screenWidth = MediaQuery.of(context).size.width;
                      final hasEnoughSpace = screenWidth > 600;

                      if (hasEnoughSpace) {
                        // Desktop/tablet layout - buttons in a row
                        return Row(
                          children: [
                            // Add New User button
                            ElevatedButton.icon(
                              onPressed: _showAddUserDialog,
                              icon: Icon(Icons.add,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                l10n.addNewUser,
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Add Holiday Policy button
                            ElevatedButton.icon(
                              onPressed: _showHolidayPolicyDialog,
                              icon: Icon(Icons.calendar_today,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                'Add Holiday Policy',
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Add Time Off Policy button
                            ElevatedButton.icon(
                              onPressed: _showTimeOffPolicyDialog,
                              icon: Icon(Icons.schedule,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                'Add Time Off Policy',
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Mobile layout - buttons stacked
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Add New User button
                            ElevatedButton.icon(
                              onPressed: _showAddUserDialog,
                              icon: Icon(Icons.add,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                l10n.addNewUser,
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Add Holiday Policy button
                            ElevatedButton.icon(
                              onPressed: _showHolidayPolicyDialog,
                              icon: Icon(Icons.calendar_today,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                'Add Holiday Policy',
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Add Time Off Policy button
                            ElevatedButton.icon(
                              onPressed: _showTimeOffPolicyDialog,
                              icon: Icon(Icons.schedule,
                                  color: appColors.whiteTextOnBlue),
                              label: Text(
                                'Add Time Off Policy',
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isProtectedUser =
                        data['roles']?.contains('super_admin') == true;

                    return Card(
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
                                          .withOpacity(0.2),
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
