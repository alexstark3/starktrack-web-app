import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
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
    final person = '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client name
        Text(
          client['name'] ?? '',
          style: TextStyle(
            fontSize: 22,
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
          label: const Text('Edit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryBlue,
            foregroundColor: colors.whiteTextOnBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 14),
        // Info fields - left aligned in column
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.isNotEmpty) _infoRow('Address', address),
            if (person.isNotEmpty) _infoRow('Contact Person', person),
            if (email.isNotEmpty) _infoRow('Email', email),
            if (phone.isNotEmpty) _infoRow('Phone', phone),
            if ((client['city'] ?? '').isNotEmpty) _infoRow('City', client['city'] ?? ''),
            if (country.isNotEmpty) _infoRow('Country', country),
          ],
        ),
        const SizedBox(height: 24),
        // Projects list for this client
        Text('Projects for this client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: colors.primaryBlue)),
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
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No projects found for this client.'),
              );
            }
            return Column(
              children: [
                _projectTableHeader(colors),
                ...projects.map((proj) => _ProjectRow(
                  companyId: widget.companyId,
                  project: proj,
                )),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _projectTableHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.lightGray, width: 1)),
        color: colors.lightGray.withOpacity(0.35),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Project Name', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Project ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Total Hours', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> project;
  const _ProjectRow({
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
        final expensesText = expenses > 0 ? expenses.toStringAsFixed(2) + ' CHF' : '-';
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(project['name'] ?? '')),
              Expanded(flex: 2, child: Text(project['project_id'] ?? '')),
              Expanded(flex: 3, child: Text(address)),
              Expanded(flex: 2, child: Text(hoursText)),
              Expanded(flex: 2, child: Text(expensesText)),
            ],
          ),
        );
      },
    );
  }
}
