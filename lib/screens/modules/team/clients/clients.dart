import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'view_clients.dart';

class ClientsTab extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic>? selectedClient;
  final void Function(Map<String, dynamic> client)? onSelectClient;

  const ClientsTab({
    Key? key,
    required this.companyId,
    this.selectedClient,
    this.onSelectClient,
  }) : super(key: key);

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    // If a client is selected, show ViewClients (details)
    if (widget.selectedClient != null && widget.selectedClient!['id'] != null) {
      return ViewClients(
        companyId: widget.companyId,
        client: widget.selectedClient!,
        onEdit: () => widget.onSelectClient?.call({}), // clear view to go back to list
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar + Add button
          Row(
            children: [
              Expanded(
                flex: 2,
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
                      hintText: 'Search by client name, person, or email',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: TextStyle(color: colors.textColor),
                    onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                  ),
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
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // client dialog code
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
                    child: _ClientsTable(
                      companyId: widget.companyId,
                      search: _search,
                      onSelectClient: (clientData) => widget.onSelectClient?.call(clientData),
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
  final void Function(Map<String, dynamic> clientData) onSelectClient;

  const _ClientsTable({
    Key? key,
    required this.companyId,
    required this.search,
    required this.onSelectClient,
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
          final person =
              '${(contact['first_name'] ?? '').toString().toLowerCase()} ${(contact['surname'] ?? '').toString().toLowerCase()}';
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
            DataColumn(label: Text('')),
            DataColumn(label: Text('Client Name')),
            DataColumn(label: Text('Address')),
            DataColumn(label: Text('Contact Person')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Country')),
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

            return DataRow(
              cells: [
                DataCell(
                  ElevatedButton(
                    onPressed: () => onSelectClient({...data, 'id': doc.id}),
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
                DataCell(Text(clientName, style: TextStyle(color: colors.textColor))),
                DataCell(Text(address, style: TextStyle(color: colors.textColor))),
                DataCell(Text(person, style: TextStyle(color: colors.textColor))),
                DataCell(Text(email, style: TextStyle(color: colors.textColor))),
                DataCell(Text(phone, style: TextStyle(color: colors.textColor))),
                DataCell(Text(city, style: TextStyle(color: colors.textColor))),
                DataCell(Text(country, style: TextStyle(color: colors.textColor))),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
