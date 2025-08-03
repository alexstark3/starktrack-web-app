import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'view_clients.dart';
import 'add_client_dialog.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    // If a client is selected, show ViewClients (details)
    if (widget.selectedClient != null && widget.selectedClient!['id'] != null) {
      return ViewClients(
        companyId: widget.companyId,
        client: widget.selectedClient!,
        onEdit: () =>
            widget.onSelectClient?.call({}), // clear view to go back to list
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar + Add button in a card
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
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colors.lightGray
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : Border.all(color: Colors.black26, width: 1),
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
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchByClientNamePersonEmail,
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
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
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l10n.addNew),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (ctx) =>
                          AddClientDialog(companyId: widget.companyId),
                    );
                    if (result == true) {
                      // Refresh the clients list
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _ClientsTable(
              companyId: widget.companyId,
              search: _search,
              onSelectClient: (clientData) =>
                  widget.onSelectClient?.call(clientData),
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
    final l10n = AppLocalizations.of(context)!;
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
          return Center(child: Text(l10n.noClientsFound));
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
          return Center(child: Text(l10n.noClientsFound));
        }

        return ListView.builder(
          key: ValueKey('clients_list_$search'),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final contact = data['contact_person'] ?? {};
            final clientName = (data['name'] ?? '').toString();
            final address = [
              (data['street'] ?? ''),
              (data['number'] ?? ''),
              (data['post_code'] ?? ''),
              (data['city'] ?? '')
            ].where((e) => (e as String).isNotEmpty).join(' ');
            final person =
                '${contact['first_name'] ?? ''} ${contact['surname'] ?? ''}'
                    .trim();
            final email = data['email'] ?? '';
            final phone = data['phone'] ?? '';
            final city = data['city'] ?? '';
            final country = data['country'] ?? '';

            return Card(
              key: ValueKey('client_item_${doc.id}'),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business,
                            color: colors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (city.isNotEmpty || country.isNotEmpty)
                                Text(
                                  [city, country]
                                      .where((e) => e.isNotEmpty)
                                      .join(', '),
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
                    if (address.isNotEmpty) ...[
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
                      const SizedBox(height: 8),
                    ],
                    if (person.isNotEmpty) ...[
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
                              person,
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
                    if (email.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: colors.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
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
                    if (phone.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: colors.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textColor.withOpacity(0.8),
                              ),
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
                          onPressed: () =>
                              onSelectClient({...data, 'id': doc.id}),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: Text(l10n.view),
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
}
