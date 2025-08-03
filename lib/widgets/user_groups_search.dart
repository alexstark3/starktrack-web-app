import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class UserGroupSelectionDialog extends StatefulWidget {
  final String companyId;
  final List<String> selectedUsers;
  final List<String> selectedGroups;
  final Function(List<String>, List<String>) onSelectionChanged;

  const UserGroupSelectionDialog({
    super.key,
    required this.companyId,
    required this.selectedUsers,
    required this.selectedGroups,
    required this.onSelectionChanged,
  });

  @override
  State<UserGroupSelectionDialog> createState() =>
      _UserGroupSelectionDialogState();
}

class _UserGroupSelectionDialogState extends State<UserGroupSelectionDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  List<String> _selectedUsers = [];
  List<String> _selectedGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.selectedUsers);
    _selectedGroups = List.from(widget.selectedGroups);
    _loadUsersAndGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersAndGroups() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Load users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .get();

      _users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = data['firstName'] ?? '';
        final surname = data['surname'] ?? '';
        final fullName = '$firstName $surname'.trim();
        return {
          'id': doc.id,
          'name': fullName.isNotEmpty ? fullName : l10n.unknownUser,
          'email': data['email'] ?? '',
          'type': 'user',
        };
      }).toList();

      // Load groups (you might need to adjust this based on your data structure)
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('groups')
          .get();

      _groups = groupsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? l10n.unknownGroup,
          'type': 'group',
        };
      }).toList();

      _filteredUsers = List.from(_users);
      _filteredGroups = List.from(_groups);
    } catch (e) {
      print('Error loading users and groups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_users);
        _filteredGroups = List.from(_groups);
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredUsers = _users.where((user) {
          return user['name']
                  .toString()
                  .toLowerCase()
                  .contains(lowercaseQuery) ||
              user['email'].toString().toLowerCase().contains(lowercaseQuery);
        }).toList();
        _filteredGroups = _groups.where((group) {
          return group['name']
              .toString()
              .toLowerCase()
              .contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
    widget.onSelectionChanged(_selectedUsers, _selectedGroups);
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedGroups.contains(groupId)) {
        _selectedGroups.remove(groupId);
      } else {
        _selectedGroups.add(groupId);
      }
    });
    widget.onSelectionChanged(_selectedUsers, _selectedGroups);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.assignToUsers,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: appColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchUsersAndGroups,
                  prefixIcon: Icon(Icons.search, color: appColors.primaryBlue),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: _filterItems,
              ),
            ),
            const SizedBox(height: 20),

            // Results area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty && _filteredGroups.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noUsersOrGroupsFound,
                            style: TextStyle(color: appColors.textColor),
                          ),
                        )
                      : ListView(
                          children: [
                            if (_filteredUsers.isNotEmpty) ...[
                              Text(
                                l10n.users,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._filteredUsers.map((user) => CheckboxListTile(
                                    title: Text(user['name']),
                                    subtitle: Text(user['email']),
                                    value: _selectedUsers.contains(user['id']),
                                    onChanged: (_) =>
                                        _toggleUserSelection(user['id']),
                                    activeColor: appColors.primaryBlue,
                                  )),
                              const SizedBox(height: 16),
                            ],
                            if (_filteredGroups.isNotEmpty) ...[
                              Text(
                                l10n.groups,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._filteredGroups
                                  .map((group) => CheckboxListTile(
                                        title: Text(group['name']),
                                        value: _selectedGroups
                                            .contains(group['id']),
                                        onChanged: (_) =>
                                            _toggleGroupSelection(group['id']),
                                        activeColor: appColors.primaryBlue,
                                      )),
                            ],
                          ],
                        ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: appColors.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primaryBlue,
                    foregroundColor: appColors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Embedded version for direct use in forms
class EmbeddedUserGroupSearch extends StatefulWidget {
  final String companyId;
  final List<String> selectedUsers;
  final List<String> selectedGroups;
  final Function(List<String>, List<String>) onSelectionChanged;

  const EmbeddedUserGroupSearch({
    super.key,
    required this.companyId,
    required this.selectedUsers,
    required this.selectedGroups,
    required this.onSelectionChanged,
  });

  @override
  State<EmbeddedUserGroupSearch> createState() =>
      _EmbeddedUserGroupSearchState();
}

class _EmbeddedUserGroupSearchState extends State<EmbeddedUserGroupSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  List<String> _localSelectedUsers = [];
  List<String> _localSelectedGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localSelectedUsers = List<String>.from(widget.selectedUsers);
    _localSelectedGroups = List<String>.from(widget.selectedGroups);
    _loadUsersAndGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmbeddedUserGroupSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state with parent state
    _localSelectedUsers = List<String>.from(widget.selectedUsers);
    _localSelectedGroups = List<String>.from(widget.selectedGroups);
  }

  Future<void> _loadUsersAndGroups() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _isLoading = true);

      // Load users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .get();

      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = data['firstName'] ?? '';
        final surname = data['surname'] ?? '';
        final fullName = '$firstName $surname'.trim();
        return {
          'id': doc.id,
          'name': fullName,
          'email': data['email'] ?? '',
        };
      }).toList();

      // Load groups
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('groups')
          .get();

      final groups = groupsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? l10n.unknownGroup,
        };
      }).toList();

      setState(() {
        _users = users;
        _groups = groups;
        _filteredUsers = users;
        _filteredGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_users);
        _filteredGroups = List.from(_groups);
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredUsers = _users.where((user) {
          final name = user['name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          return name.contains(lowercaseQuery) ||
              email.contains(lowercaseQuery);
        }).toList();
        _filteredGroups = _groups.where((group) {
          final name = group['name']?.toString().toLowerCase() ?? '';
          return name.contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_localSelectedUsers.contains(userId)) {
        _localSelectedUsers.remove(userId);
      } else {
        _localSelectedUsers.add(userId);
      }
    });
    widget.onSelectionChanged(_localSelectedUsers, _localSelectedGroups);
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_localSelectedGroups.contains(groupId)) {
        _localSelectedGroups.remove(groupId);
      } else {
        _localSelectedGroups.add(groupId);
      }
    });
    widget.onSelectionChanged(_localSelectedUsers, _localSelectedGroups);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: appColors.lightGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchUsersAndGroups,
                prefixIcon: Icon(Icons.search, color: appColors.primaryBlue),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: _filterItems,
            ),
          ),

          // Results area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: appColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty && _filteredGroups.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noUsersOrGroupsFound,
                            style: TextStyle(color: appColors.textColor),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            if (_filteredUsers.isNotEmpty) ...[
                              Text(
                                l10n.users,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              ..._filteredUsers.map((user) => CheckboxListTile(
                                    title: Text(user['name']),
                                    subtitle: Text(user['email']),
                                    value: _localSelectedUsers
                                        .contains(user['id']),
                                    onChanged: (value) {
                                      _toggleUserSelection(user['id']);
                                    },
                                    activeColor: appColors.primaryBlue,
                                    dense: true,
                                  )),
                            ],
                            if (_filteredGroups.isNotEmpty) ...[
                              Text(
                                l10n.groups,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              ..._filteredGroups
                                  .map((group) => CheckboxListTile(
                                        title: Text(group['name']),
                                        value: _localSelectedGroups
                                            .contains(group['id']),
                                        onChanged: (value) {
                                          _toggleGroupSelection(group['id']);
                                        },
                                        activeColor: appColors.primaryBlue,
                                        dense: true,
                                      )),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
