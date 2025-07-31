import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'add_client_dialog.dart';

class ViewClients extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> client;
  final VoidCallback onEdit;

  const ViewClients({
    Key? key,
    required this.companyId,
    required this.client,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<ViewClients> createState() => _ViewClientsState();
}

class _ViewClientsState extends State<ViewClients> {
  late Future<List<Map<String, dynamic>>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _fetchClientProjects();
  }

  Future<List<Map<String, dynamic>>> _fetchClientProjects() async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .where('client', isEqualTo: widget.client['id'])
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final client = widget.client;
    final contact = client['contact_person'] ?? {};
    final address = [
      client['street'] ?? '',
      client['number'] ?? '',
      client['post_code'] ?? '',
      client['city'] ?? ''
    ].where((e) => (e as String).isNotEmpty).join(' ');

    final country = client['country'] ?? '';
    final email = client['email'] ?? '';
    final phone = client['phone'] ?? '';
    final person =
        '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'.trim();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client name
            Text(
              client['name'] ?? '',
              style: TextStyle(
                fontSize: 18, // Reduced from 22 to 18
                fontWeight: FontWeight.bold,
                color: colors.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            // Edit button - left aligned under name
            ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => EditClientDialog(
                    companyId: widget.companyId,
                    client: widget.client,
                  ),
                );
                if (result == true) {
                  widget.onEdit(); // Call the callback to refresh the parent
                }
              },
              icon: const Icon(Icons.edit, size: 20),
              label: Text(AppLocalizations.of(context)!.edit),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.whiteTextOnBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            // Info fields - left aligned in column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isNotEmpty)
                  _infoRow(AppLocalizations.of(context)!.address, address),
                if (person.isNotEmpty)
                  _infoRow(AppLocalizations.of(context)!.contactPerson, person),
                if (email.isNotEmpty)
                  _infoRow(AppLocalizations.of(context)!.email, email),
                if (phone.isNotEmpty)
                  _infoRow(AppLocalizations.of(context)!.phone, phone),
                if ((client['city'] ?? '').isNotEmpty)
                  _infoRow(
                      AppLocalizations.of(context)!.city, client['city'] ?? ''),
                if (country.isNotEmpty)
                  _infoRow(AppLocalizations.of(context)!.country, country),
              ],
            ),
            const SizedBox(height: 24),
            // Projects list for this client
            Text(AppLocalizations.of(context)!.projectsForThisClient,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: colors.primaryBlue)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _projectsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final projects = snap.data ?? [];
                if (projects.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(AppLocalizations.of(context)!
                        .noProjectsFoundForThisClient),
                  );
                }
                return Column(
                  children: [
                    // Client totals summary
                    _ClientTotalsCard(
                      companyId: widget.companyId,
                      projects: projects,
                    ),
                    const SizedBox(height: 16),
                    // Individual project cards
                    ...projects.map((project) => _ProjectCard(
                          companyId: widget.companyId,
                          project: project,
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                value,
                maxLines: null,
                softWrap: true,
              ),
            ),
          ],
        ),
      );
}

class _ProjectCard extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> project;
  const _ProjectCard({
    Key? key,
    required this.companyId,
    required this.project,
  }) : super(key: key);

  Future<Map<String, dynamic>> _totals() async {
    double totalHours = 0;
    double totalExpenses = 0;
    final usersSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .get();
    for (final userDoc in usersSnap.docs) {
      final logsSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs')
          .where('projectId', isEqualTo: project['id'])
          .get();
      for (final log in logsSnap.docs) {
        final data = log.data();
        totalHours += (data['duration_minutes'] ?? 0) / 60.0;
        final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
        for (var v in expenses.values) {
          if (v is num) totalExpenses += v.toDouble();
        }
      }
    }
    return {
      'hours': totalHours,
      'expenses': totalExpenses,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final address = [
      project['address']?['street'] ?? '',
      project['address']?['number'] ?? '',
      project['address']?['post_code'] ?? '',
      project['address']?['city'] ?? ''
    ].where((e) => (e as String).isNotEmpty).join(' ');

    return FutureBuilder<Map<String, dynamic>>(
      future: _totals(),
      builder: (context, snap) {
        double hours = snap.data?['hours'] ?? 0;
        double expenses = snap.data?['expenses'] ?? 0;
        final hoursText = hours > 0 ? hours.toStringAsFixed(2) : '-';
        final expensesText =
            expenses > 0 ? expenses.toStringAsFixed(2) + ' CHF' : '-';

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
                Text(
                  project['name'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${project['projectRef'] ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textColor.withOpacity(0.7),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalTime}: $hoursText',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalExpenses}: $expensesText',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.8),
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
  }
}

class _ClientTotalsCard extends StatelessWidget {
  final String companyId;
  final List<Map<String, dynamic>> projects;

  const _ClientTotalsCard({
    Key? key,
    required this.companyId,
    required this.projects,
  }) : super(key: key);

  Future<Map<String, dynamic>> _calculateTotals() async {
    double totalHours = 0;
    double totalExpenses = 0;

    final usersSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .get();

    for (final userDoc in usersSnap.docs) {
      for (final project in projects) {
        final logsSnap = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('users')
            .doc(userDoc.id)
            .collection('all_logs')
            .where('projectId', isEqualTo: project['id'])
            .get();
        for (final log in logsSnap.docs) {
          final data = log.data();
          totalHours += (data['duration_minutes'] ?? 0) / 60.0;
          final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
          for (var v in expenses.values) {
            if (v is num) totalExpenses += v.toDouble();
          }
        }
      }
    }

    return {
      'hours': totalHours,
      'expenses': totalExpenses,
      'projectCount': projects.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateTotals(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final totals =
            snap.data ?? {'hours': 0.0, 'expenses': 0.0, 'projectCount': 0};
        final hours = totals['hours'] as double;
        final expenses = totals['expenses'] as double;
        final projectCount = totals['projectCount'] as int;

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
                Text(
                  AppLocalizations.of(context)!.clientSummary,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.total} ${AppLocalizations.of(context)!.projects}: $projectCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalTime}: ${hours.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalExpenses}: ${expenses.toStringAsFixed(2)} CHF',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withOpacity(0.8),
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
  }
}
