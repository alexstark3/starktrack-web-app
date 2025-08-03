import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AddGroupDialog extends StatefulWidget {
  final String companyId;
  final DocumentSnapshot? groupDoc; // null for new group, not null for editing

  const AddGroupDialog({
    super.key,
    required this.companyId,
    this.groupDoc,
  });

  @override
  State<AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<AddGroupDialog> {
  final _groupNameController = TextEditingController();
  String? _selectedTeamLeader;
  Set<String> _selectedMembers = {};
  String _memberSearchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    if (widget.groupDoc != null) {
      final data = widget.groupDoc!.data() as Map<String, dynamic>;
      _groupNameController.text = data['name'] ?? '';
      _selectedTeamLeader = data['team_leader'] ?? '';
      _selectedMembers = Set<String>.from(data['members'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.groupDoc != null;

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
            // Group Name Field
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

            // Team Leader Dropdown
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

            // Members Section Header
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
                    key: ValueKey('add_group_users_list_$_memberSearchQuery'),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final firstName = data['firstName'] ?? '';
                      final surname = data['surname'] ?? '';
                      final fullName = '$firstName $surname'.trim();
                      final email = data['email'] ?? '';

                      return ListTile(
                        key: ValueKey('add_group_user_${doc.id}'),
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
          onPressed: _isLoading ? null : _saveGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryBlue,
            foregroundColor: colors.whiteTextOnBlue,
          ),
          child: _isLoading
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

  Future<void> _saveGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupData = {
        'name': _groupNameController.text.trim(),
        'team_leader': _selectedTeamLeader ?? '',
        'members': _selectedMembers.toList(),
        'member_count': _selectedMembers.length,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (widget.groupDoc != null) {
        // Update existing group
        await widget.groupDoc!.reference.update(groupData);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.groupDoc != null
                  ? 'Group updated successfully'
                  : 'Group created successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
