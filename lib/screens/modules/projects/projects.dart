import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_search_field.dart';
import 'add_project_dialog.dart';
import 'project_view_page.dart';

class ProjectsTab extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic>? selectedProject;
  final Function(Map<String, dynamic>? project) onSelectProject;

  const ProjectsTab({
    super.key,
    required this.companyId,
    required this.selectedProject,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedProject != null) {
      return ProjectViewPage(
        companyId: companyId,
        project: selectedProject!,
        onClose: () => onSelectProject(null),
      );
    }
    return _ProjectsList(
      companyId: companyId,
      onSelectProject: onSelectProject,
    );
  }
}

class _ProjectsList extends StatefulWidget {
  final String companyId;
  final Function(Map<String, dynamic> project) onSelectProject;

  const _ProjectsList({
    required this.companyId,
    required this.onSelectProject,
  });

  @override
  State<_ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<_ProjectsList> {
  String _searchProject = '';
  String _searchClient = '';

  Future<Map<String, Map<String, dynamic>>> _batchFetchClients(
    BuildContext context,
    List<QueryDocumentSnapshot> filtered,
    String companyId,
  ) async {
    final ids = filtered
        .map((doc) => (doc.data() as Map<String, dynamic>)['client'] ?? '')
        .where((id) => id.toString().isNotEmpty)
        .toSet();

    Map<String, Map<String, dynamic>> result = {};
    for (final clientId in ids) {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .doc(clientId)
          .get();
      if (doc.exists) result[clientId] = doc.data()!;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                if (isCompact) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 120,
                        child: AppSearchField(
                          hintText:
                              AppLocalizations.of(context)!.searchByProject,
                          onChanged: (val) => setState(
                              () => _searchProject = val.trim().toLowerCase()),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: AppSearchField(
                          hintText:
                              AppLocalizations.of(context)!.searchByClient,
                          prefixIcon: Icons.grid_on,
                          onChanged: (val) => setState(
                              () => _searchClient = val.trim().toLowerCase()),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 38,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(AppLocalizations.of(context)!.addNew),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: colors.whiteTextOnBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(120, 38),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  AddProjectDialog(companyId: widget.companyId),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hintText: AppLocalizations.of(context)!.searchByProject,
                        onChanged: (val) => setState(
                            () => _searchProject = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppSearchField(
                        hintText: AppLocalizations.of(context)!.searchByClient,
                        prefixIcon: Icons.grid_on,
                        onChanged: (val) => setState(
                            () => _searchClient = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      height: 38,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(AppLocalizations.of(context)!.addNew),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          foregroundColor: colors.whiteTextOnBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(120, 38),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) =>
                                AddProjectDialog(companyId: widget.companyId),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('projects')
                  .orderBy(FieldPath.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child:
                          Text(AppLocalizations.of(context)!.noProjectsFound));
                }
                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final projectName =
                      (data['name'] ?? '').toString().toLowerCase();
                  final clientId =
                      (data['client'] ?? '').toString().toLowerCase();
                  return projectName.contains(_searchProject) &&
                      clientId.contains(_searchClient);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                      child:
                          Text(AppLocalizations.of(context)!.noProjectsFound));
                }

                // Sort projects: active projects first, then by name
                filtered.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aActive = aData['active'] == true;
                  final bActive = bData['active'] == true;

                  if (aActive != bActive) {
                    return aActive ? -1 : 1; // Active projects first
                  }

                  // If both have same active status, sort by name
                  final aName = (aData['name'] ?? '').toString().toLowerCase();
                  final bName = (bData['name'] ?? '').toString().toLowerCase();
                  return aName.compareTo(bName);
                });

                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future:
                      _batchFetchClients(context, filtered, widget.companyId),
                  builder: (context, clientSnapshot) {
                    final clientsMap = clientSnapshot.data ?? {};

                    return ListView.builder(
                      key: ValueKey('projects_list_$_searchProject'),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final address = data['address'] ?? {};
                        final projectId = data['projectRef'] ?? '';
                        final projectName = data['name'] ?? '';
                        final addressString = [
                          address['street'],
                          address['number'],
                          address['post_code'],
                          address['city'],
                        ]
                            .where((e) => e != null && e.toString().isNotEmpty)
                            .map((e) => e.toString())
                            .join(' ');
                        final clientId = data['client'] ?? '';

                        final clientData = clientsMap[clientId];
                        final clientName = clientData?['name'] ?? '';
                        final contact = clientData?['contact_person'] ?? {};
                        final contactPerson =
                            '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'
                                .trim();
                        final phone = clientData?['phone'] ?? '';
                        final email = clientData?['email'] ?? '';

                        final isActive = data['active'] == true;

                        return Card(
                          key: ValueKey('project_item_${doc.id}'),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await doc.reference.update({
                                          'active': !isActive,
                                        });
                                      },
                                      child: Icon(
                                        Icons.folder_copy_rounded,
                                        color: isActive
                                            ? Colors.green
                                            : colors.primaryBlue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            projectName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: colors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${AppLocalizations.of(context)!.projectId}: $projectId',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colors.textColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (addressString.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: colors.textColor
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          addressString,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.textColor
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (clientName.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business,
                                        size: 16,
                                        color: colors.textColor
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${AppLocalizations.of(context)!.clientName}: $clientName',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.textColor
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (contactPerson.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: colors.textColor
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${AppLocalizations.of(context)!.contactPerson}: $contactPerson',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.textColor
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (phone.isNotEmpty || email.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.contact_phone,
                                        size: 16,
                                        color: colors.textColor
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (phone.isNotEmpty)
                                              Text(
                                                phone,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colors.textColor
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colors.textColor
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        widget.onSelectProject(
                                            {...data, 'id': doc.id});
                                      },
                                      icon: const Icon(Icons.visibility,
                                          size: 16),
                                      label: Text(
                                          AppLocalizations.of(context)!.view),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primaryBlue,
                                        foregroundColor: colors.whiteTextOnBlue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
