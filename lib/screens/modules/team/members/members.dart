import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'members_view.dart';

class MembersTab extends StatelessWidget {
  final String companyId;
  final String? teamLeaderId;
  final DocumentSnapshot? selectedMember;
  final void Function(DocumentSnapshot?) onSelectMember;

  const MembersTab({
    Key? key,
    required this.companyId,
    this.teamLeaderId,
    required this.selectedMember,
    required this.onSelectMember,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedMember != null) {
      return MemberHistoryScreen(
        companyId: companyId,
        memberDoc: selectedMember!,
        onBack: () => onSelectMember(null), // <- Correct usage for back
      );
    }

    final colors = Theme.of(context).extension<AppColors>()!;
    String _search = '';

    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, surname or email',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.midGray),
                ),
                filled: true,
                fillColor: colors.lightGray,
              ),
              style: TextStyle(color: colors.textColor),
              onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        maxWidth: double.infinity,
                      ),
                      child: _MembersTable(
                        companyId: companyId,
                        search: _search,
                        teamLeaderId: teamLeaderId,
                        onView: onSelectMember,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
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
          return const Center(child: Text('No members found.'));
        }
        final docs = snapshot.data!.docs;
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final firstName = (data['firstName'] ?? '').toString().toLowerCase();
          final surname = (data['surname'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final isNotTeamLeader = teamLeaderId == null || doc.id != teamLeaderId;
          return isNotTeamLeader &&
              (firstName.contains(search) ||
               surname.contains(search) ||
               email.contains(search));
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No members found.'));
        }

        return DataTable(
          columns: const [
            DataColumn(label: Text('Actions')),
            DataColumn(label: Text('First Name')),
            DataColumn(label: Text('Surname')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
          ],
          rows: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final firstName = data['firstName'] ?? '';
            final surname = data['surname'] ?? '';
            final email = data['email'] ?? '';
            final phone = data['phone'] ?? '';
            return DataRow(cells: [
              DataCell(
                ElevatedButton(
                  onPressed: () => onView(doc),
                  child: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    minimumSize: const Size(48, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              DataCell(Text(firstName, style: TextStyle(color: colors.textColor))),
              DataCell(Text(surname, style: TextStyle(color: colors.textColor))),
              DataCell(Text(email, style: TextStyle(color: colors.textColor))),
              DataCell(Text(phone, style: TextStyle(color: colors.textColor))),
            ]);
          }).toList(),
        );
      },
    );
  }
}
