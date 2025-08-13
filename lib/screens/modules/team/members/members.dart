import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'members_view.dart';

class MembersTab extends StatefulWidget {
  final String companyId;
  final String? teamLeaderId;
  final DocumentSnapshot? selectedMember;
  final void Function(DocumentSnapshot?) onSelectMember;

  const MembersTab({
    super.key,
    required this.companyId,
    this.teamLeaderId,
    required this.selectedMember,
    required this.onSelectMember,
  });

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMember != null) {
      return MemberHistoryScreen(
        companyId: widget.companyId,
        memberDoc: widget.selectedMember!,
        onBack: () => widget.onSelectMember(null),
      );
    }

    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black26,
                width: 1,
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.lightGray
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context)?.searchByNameSurnameEmail ??
                        'Search by name, surname or email',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB3B3B3)
                      : colors.textColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB3B3B3)
                      : colors.darkGray,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCCCCCC)
                    : colors.textColor,
              ),
              onChanged: (val) =>
                  setState(() => _search = val.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _MembersTable(
              companyId: widget.companyId,
              search: _search,
              teamLeaderId: widget.teamLeaderId,
              onView: widget.onSelectMember,
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTable extends StatelessWidget {
  final String companyId;
  final String search;
  final String? teamLeaderId;
  final void Function(DocumentSnapshot) onView;

  const _MembersTable({
    Key? key,
    required this.companyId,
    required this.search,
    this.teamLeaderId,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .orderBy('surname')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(l10n?.noMembersFound ?? 'No members found.'));
        }
        final docs = snapshot.data!.docs;
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final firstName = (data['firstName'] ?? '').toString().toLowerCase();
          final surname = (data['surname'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final userTeamLeader = data['teamLeader'] ?? '';

          // Apply team leader filter if specified
          if (teamLeaderId != null && teamLeaderId!.isNotEmpty) {
            if (userTeamLeader != teamLeaderId) {
              return false;
            }
          }

          return (firstName.contains(search) ||
              surname.contains(search) ||
              email.contains(search));
        }).toList();

        if (filtered.isEmpty) {
          return Center(
              child: Text(l10n?.noMembersFound ?? 'No members found.'));
        }

        return ListView.builder(
          key: ValueKey('members_list_$search'),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final firstName = (data['firstName'] ?? '').toString();
            final surname = (data['surname'] ?? '').toString();
            final email = (data['email'] ?? '').toString();
            final roles = _formatRoles(data['roles'] as List?, l10n);
            final modules = _formatModules(data['modules'] as List?, l10n);

            return Container(
              key: ValueKey('member_item_${doc.id}'),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$firstName $surname',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MemberStatusIcon(
                                companyId: companyId, userId: doc.id),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFCCCCCC)
                                    : colors.textColor,
                          ),
                        ),
                      ],
                    ),
                    if (roles.isNotEmpty || modules.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      if (roles.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              size: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF666666),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n?.roles ?? 'Roles'}: $roles',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFA3A3A3)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (modules.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.apps,
                              size: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF666666),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n?.modules ?? 'Modules'}: $modules',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFA3A3A3)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // View button
                        ElevatedButton.icon(
                          onPressed: () => onView(doc),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: Text(l10n?.view ?? 'View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: colors.whiteTextOnBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatRoles(List? roles, AppLocalizations? l10n) {
    if (roles == null || roles.isEmpty) {
      return '';
    }

    return roles.map((role) {
      switch (role.toString()) {
        case 'admin':
          return l10n?.role_admin ?? 'Admin';
        case 'team_leader':
          return l10n?.role_team_leader ?? 'Team Leader';
        case 'company_admin':
          return l10n?.role_company_admin ?? 'Company Admin';
        case 'user':
          return l10n?.role_user ?? 'User';
        case 'worker':
          return l10n?.role_worker ?? 'Worker';
        default:
          return role.toString();
      }
    }).join(', ');
  }

  String _formatModules(List? modules, AppLocalizations? l10n) {
    if (modules == null || modules.isEmpty) {
      return '';
    }

    return modules.map((module) {
      switch (module.toString()) {
        case 'admin':
          return l10n?.module_admin ?? 'Administration';
        case 'time_tracker':
          return l10n?.module_time_tracker ?? 'Time Tracker';
        case 'team':
          return l10n?.module_team ?? 'Team Management';
        case 'history':
          return l10n?.module_history ?? 'History';
        default:
          return module.toString();
      }
    }).join(', ');
  }
}

class _MemberStatusIcon extends StatelessWidget {
  final String companyId;
  final String userId;

  const _MemberStatusIcon({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: todayStr)
          .snapshots(),
      builder: (context, snapshot) {
        bool isWorking = false;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final hasBegin = data['begin'] != null;
            final hasEnd = data['end'] != null;
            if (hasBegin && !hasEnd) {
              isWorking = true;
              break;
            }
          }
        }
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isWorking ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
