import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_group.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
                    controller: _searchController,
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
                  key: ValueKey('groups_list_$_searchQuery'),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final doc = filteredGroups[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final groupName = data['name'] ?? 'Unnamed Group';
                    final teamLeader = data['team_leader'] ?? '';
                    final memberCount = data['member_count'] ?? 0;

                    return Container(
                      key: ValueKey('group_item_${doc.id}'),
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
    showDialog(
      context: context,
      builder: (context) => AddGroupDialog(
        companyId: widget.companyId,
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, DocumentSnapshot groupDoc) {
    showDialog(
      context: context,
      builder: (context) => AddGroupDialog(
        companyId: widget.companyId,
        groupDoc: groupDoc,
      ),
    );
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
