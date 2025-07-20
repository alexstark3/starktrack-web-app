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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                    width: 1,
                  ),
                  color: colors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by project name',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(color: colors.textColor),
                  onChanged: (val) => setState(() => _searchProject = val.trim().toLowerCase()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                    width: 1,
                  ),
                  color: colors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by client',
                    prefixIcon: const Icon(Icons.grid_on),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(color: colors.textColor),
                  onChanged: (val) => setState(() => _searchClient = val.trim().toLowerCase()),
                ),
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
                future: _batchFetchClients(context, filtered, widget.companyId),
                builder: (context, clientSnapshot) {
                  final clientsMap = clientSnapshot.data ?? {};

                  return ListView.builder(
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
                          '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'.trim();
                      final phone = clientData?['phone'] ?? '';
                      final email = clientData?['email'] ?? '';

                      final isActive = data['active'] == true;
                      
                      return Card(
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
                                      color: isActive ? Colors.green : colors.primaryBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          'ID: $projectId',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.textColor.withOpacity(0.7),
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
                                      color: colors.textColor.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        addressString,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.textColor.withOpacity(0.8),
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
                                      color: colors.textColor.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Client: $clientName',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.textColor.withOpacity(0.8),
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
                                      color: colors.textColor.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Contact: $contactPerson',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.textColor.withOpacity(0.8),
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
                                      color: colors.textColor.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (phone.isNotEmpty)
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colors.textColor.withOpacity(0.8),
                                              ),
                                            ),
                                          if (email.isNotEmpty)
                                            Text(
                                              email,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colors.textColor.withOpacity(0.8),
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
                                      widget.onSelectProject({...data, 'id': doc.id});
                                    },
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('View'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primaryBlue,
                                      foregroundColor: colors.whiteTextOnBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
