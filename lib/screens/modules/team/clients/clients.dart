import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'add_client_dialog.dart';

class ClientsTab extends StatefulWidget {
  final String companyId;
  const ClientsTab({Key? key, required this.companyId}) : super(key: key);

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28), // uniform padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar + Add button
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by client name, person, or email',
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
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryBlue,
                  foregroundColor: colors.whiteTextOnBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AddClientDialog(companyId: widget.companyId),
                  );
                  if (created == true) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // The list/table, stretching full width and scrolling if needed
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth, // Fills card horizontally!
                      maxWidth: double.infinity,
                    ),
                    child: _ClientsTable(
                      companyId: widget.companyId,
                      search: _search,
                      onView: (clientData) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(clientData['name'] ?? ''),
                            content: Text('View button clicked.'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientsTable extends StatelessWidget {
  final String companyId;
  final String search;
  final void Function(Map<String, dynamic> clientData) onView;

  const _ClientsTable({
    Key? key,
    required this.companyId,
    required this.search,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .orderBy(FieldPath.documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No clients found.'));
        }
        final docs = snapshot.data!.docs;
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final contact = data['contact_person'] ?? {};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final person = '${(contact['first_name'] ?? '').toString().toLowerCase()} ${(contact['surname'] ?? '').toString().toLowerCase()}';
          final email = (data['email'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? '').toString().toLowerCase();
          return name.contains(search) ||
              person.contains(search) ||
              email.contains(search) ||
              city.contains(search) ||
              phone.contains(search);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No clients found.'));
        }

        return DataTable(
          columns: const [
            DataColumn(label: Text('Client Name')),
            DataColumn(label: Text('Address')),
            DataColumn(label: Text('Contact Person')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final contact = data['contact_person'] ?? {};
            final clientName = (data['name'] ?? '').toString();
            final address = [
              (data['street'] ?? ''),
              (data['number'] ?? ''),
              (data['post_code'] ?? ''),
              (data['city'] ?? '')
            ].where((e) => (e as String).isNotEmpty).join(' ');
            final person = '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'.trim();
            final email = data['email'] ?? '';
            final phone = data['phone'] ?? '';
            final city = data['city'] ?? '';
            final country = data['country'] ?? '';

            return DataRow(cells: [
              DataCell(Text(clientName, style: TextStyle(color: colors.textColor))),
              DataCell(Text(address, style: TextStyle(color: colors.textColor))),
              DataCell(Text(person, style: TextStyle(color: colors.textColor))),
              DataCell(Text(email, style: TextStyle(color: colors.textColor))),
              DataCell(Text(phone, style: TextStyle(color: colors.textColor))),
              DataCell(Text(city, style: TextStyle(color: colors.textColor))),
              DataCell(Text(country, style: TextStyle(color: colors.textColor))),
              DataCell(
                ElevatedButton(
                  onPressed: () => onView({...data, 'id': doc.id}),
                  child: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    minimumSize: const Size(48, 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ]);
          }).toList(),
        );
      },
    );
  }
}
