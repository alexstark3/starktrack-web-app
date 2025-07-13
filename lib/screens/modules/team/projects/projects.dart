import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'add_project_dialog.dart';
import 'project_view_page.dart';

class ProjectsTab extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic>? selectedProject;
  final Function(Map<String, dynamic>? project) onSelectProject;

  const ProjectsTab({
    Key? key,
    required this.companyId,
    required this.selectedProject,
    required this.onSelectProject,
  }) : super(key: key);

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
    Key? key,
    required this.companyId,
    required this.onSelectProject,
  }) : super(key: key);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by project name',
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
                onChanged: (val) => setState(() => _searchProject = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by client',
                  prefixIcon: const Icon(Icons.grid_on),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.midGray),
                  ),
                  filled: true,
                  fillColor: colors.lightGray,
                ),
                style: TextStyle(color: colors.textColor),
                onChanged: (val) => setState(() => _searchClient = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.whiteTextOnBlue,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AddProjectDialog(companyId: widget.companyId),
                );
              },
            ),
          ],
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
                        return const Center(child: Text('No projects found.'));
                      }
                      final docs = snapshot.data!.docs;
                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final projectName = (data['name'] ?? '').toString().toLowerCase();
                        final clientId = (data['client'] ?? '').toString().toLowerCase();
                        return projectName.contains(_searchProject) &&
                            clientId.contains(_searchClient);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No projects found.'));
                      }

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        future: _batchFetchClients(context, filtered, widget.companyId),
                        builder: (context, clientSnapshot) {
                          final clientsMap = clientSnapshot.data ?? {};

                          return DataTable(
                            columns: const [
                              DataColumn(label: Text('Actions')),
                              DataColumn(label: Text('Project ID')),
                              DataColumn(label: Text('Project Name')),
                              DataColumn(label: Text('Project Address')),
                              DataColumn(label: Text('Client')),
                              DataColumn(label: Text('Contact Person')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Email')),
                            ],
                            rows: filtered.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final address = data['address'] ?? {};
                              final projectId = data['project_id'] ?? '';
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
                                  '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'.trim();
                              final phone = clientData?['phone'] ?? '';
                              final email = clientData?['email'] ?? '';

                              return DataRow(cells: [
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () {
                                      widget.onSelectProject({...data, 'id': doc.id});
                                    },
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
                                DataCell(Text(projectId, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(projectName, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(addressString, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(clientName, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(contactPerson, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(phone, style: TextStyle(color: colors.textColor))),
                                DataCell(Text(email, style: TextStyle(color: colors.textColor))),
                              ]);
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
