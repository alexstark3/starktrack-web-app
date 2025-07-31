import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class GroupsTab extends StatefulWidget {
  final String companyId;

  const GroupsTab({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  String _searchQuery = '';
  final _groupNameController = TextEditingController();
  String? _selectedTeamLeader;
  bool _isAddingGroup = false;
  Set<String> _selectedMembers = {};
  String _memberSearchQuery = '';

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar and Add button in a card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.cardColorDark
                  : colors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchGroups,
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7)
                            : colors.textColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7)
                            : colors.darkGray,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? colors.lightGray
                          : Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.black.withValues(alpha: 0.26),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.black.withValues(alpha: 0.26),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: colors.primaryBlue, width: 2),
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : colors.textColor,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddGroupDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addGroup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Groups list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('groups')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups,
                          size: 64,
                          color: colors.darkGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noGroupsFound,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createFirstGroup,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allGroups = snapshot.data!.docs;
                final filteredGroups = allGroups.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredGroups.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noGroupsMatchSearch,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.darkGray,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final doc = filteredGroups[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final groupName = data['name'] ?? 'Unnamed Group';
                    final teamLeader = data['team_leader'] ?? '';
                    final memberCount = data['member_count'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colors.cardColorDark
                            : colors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: Theme.of(context).brightness ==
                                Brightness.dark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryBlue,
                          child: Icon(
                            Icons.groups,
                            color: colors.whiteTextOnBlue,
                          ),
                        ),
                        title: Text(
                          groupName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (teamLeader.isNotEmpty)
                              Text(
                                '${l10n.teamLeaderLabel} $teamLeader',
                                style: TextStyle(
                                  color: colors.darkGray,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              '$memberCount ${memberCount != 1 ? l10n.members : l10n.member}',
                              style: TextStyle(
                                color: colors.darkGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _showEditGroupDialog(context, doc),
                              icon: Icon(
                                Icons.edit,
                                color: colors.primaryBlue,
                              ),
                              tooltip: l10n.editGroup,
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteGroupDialog(context, doc),
                              icon: Icon(
                                Icons.delete,
                                color: colors.error,
                              ),
                              tooltip: l10n.deleteGroup,
                            ),
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

  void _showAddGroupDialog(BuildContext context) {
    _groupNameController.clear();
    _selectedTeamLeader = null;
    _selectedMembers.clear();
    _memberSearchQuery = '';
    _isAddingGroup = false;

    showDialog(
      context: context,
      builder: (context) => _buildGroupDialog(context, null),
    );
  }

  void _showEditGroupDialog(BuildContext context, DocumentSnapshot groupDoc) {
    final data = groupDoc.data() as Map<String, dynamic>;
    _groupNameController.text = data['name'] ?? '';
    _selectedTeamLeader = data['team_leader'] ?? '';
    _selectedMembers = Set<String>.from(data['members'] ?? []);
    _memberSearchQuery = '';
    _isAddingGroup = false;

    showDialog(
      context: context,
      builder: (context) => _buildGroupDialog(context, groupDoc),
    );
  }

  Widget _buildGroupDialog(BuildContext context, DocumentSnapshot? groupDoc) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isEditing = groupDoc != null;

    return AlertDialog(
      title: Text(
        isEditing ? l10n.editGroup : l10n.addGroup,
        style: TextStyle(
          color: colors.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: l10n.groupName,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.26),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black26,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('users')
                  .where('roles', arrayContains: 'team_leader')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final teamLeaders = snapshot.data!.docs;
                final teamLeaderNames = teamLeaders.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return '${data['firstName'] ?? ''} ${data['surname'] ?? ''}'
                      .trim();
                }).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedTeamLeader,
                  decoration: InputDecoration(
                    labelText: l10n.teamLeaderOptional,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.primaryBlue, width: 2),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(l10n.noTeamLeader),
                    ),
                    ...teamLeaderNames.map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTeamLeader = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Member Selection Section
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: colors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.membersLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Member Search
            TextField(
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.darkGray,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black26,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black26,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.primaryBlue, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _memberSearchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 8),
            // Selected Members Display
            if (_selectedMembers.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedMembers.map((memberId) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('companies')
                          .doc(widget.companyId)
                          .collection('users')
                          .doc(memberId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final userName = userData != null
                            ? '${userData['firstName'] ?? ''} ${userData['surname'] ?? ''}'
                                .trim()
                            : l10n.unknownUser;

                        return Chip(
                          label: Text(
                            userName,
                            style: TextStyle(
                              color: colors.primaryBlue,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          deleteIcon: Icon(
                            Icons.close,
                            color: colors.primaryBlue,
                            size: 16,
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedMembers.remove(memberId);
                            });
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Available Members List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(widget.companyId)
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = snapshot.data!.docs;
                  final filteredUsers = allUsers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName =
                        (data['firstName'] ?? '').toString().toLowerCase();
                    final surname =
                        (data['surname'] ?? '').toString().toLowerCase();
                    final fullName = '$firstName $surname'.toLowerCase();
                    return fullName.contains(_memberSearchQuery) &&
                        !_selectedMembers.contains(doc.id);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _memberSearchQuery.isEmpty
                            ? l10n.noAvailableMembers
                            : l10n.noMembersMatchSearch,
                        style: TextStyle(
                          color: colors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final firstName = data['firstName'] ?? '';
                      final surname = data['surname'] ?? '';
                      final fullName = '$firstName $surname'.trim();
                      final email = data['email'] ?? '';

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor:
                              colors.primaryBlue.withValues(alpha: 0.2),
                          child: Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            color: colors.darkGray,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMembers.add(doc.id);
                            });
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: colors.primaryBlue,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed:
              _isAddingGroup ? null : () => _saveGroup(context, groupDoc),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryBlue,
            foregroundColor: colors.whiteTextOnBlue,
          ),
          child: _isAddingGroup
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? l10n.update : l10n.create),
        ),
      ],
    );
  }

  Future<void> _saveGroup(
      BuildContext context, DocumentSnapshot? groupDoc) async {
    final l10n = AppLocalizations.of(context)!;
    if (_groupNameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAddingGroup = true;
    });

    try {
      final groupData = {
        'name': _groupNameController.text.trim(),
        'team_leader': _selectedTeamLeader ?? '',
        'members': _selectedMembers.toList(),
        'member_count': _selectedMembers.length,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (groupDoc != null) {
        // Update existing group
        await groupDoc.reference.update(groupData);
      } else {
        // Create new group
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('groups')
            .add(groupData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGroupOperation(
              groupDoc != null
                  ? l10n.update.toLowerCase()
                  : l10n.create.toLowerCase(),
              e.toString(),
            )),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingGroup = false;
        });
      }
    }
  }

  void _showDeleteGroupDialog(BuildContext context, DocumentSnapshot groupDoc) {
    final l10n = AppLocalizations.of(context)!;
    final data = groupDoc.data() as Map<String, dynamic>;
    final groupName = data['name'] ?? 'this group';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGroupTitle),
        content: Text(
            '${l10n.deleteGroupConfirmation} "$groupName"? ${l10n.deleteGroupCannotBeUndone}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteGroup(groupDoc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.deleteGroup),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(DocumentSnapshot groupDoc) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await groupDoc.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupDeletedSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorDeletingGroup}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
