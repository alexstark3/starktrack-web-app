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
    super.key,
    required this.companyId,
    required this.client,
    required this.onEdit,
  });

  @override
  State<ViewClients> createState() => _ViewClientsState();
}

class _ViewClientsState extends State<ViewClients> {
  late Future<List<Map<String, dynamic>>> _projectsFuture;
  late Future<Map<String, dynamic>> _totalsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _fetchClientProjects();
    _totalsFuture = _fetchClientTotals();
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

  Future<Map<String, dynamic>> _fetchClientTotals() async {
    final projects = await _projectsFuture;
    double totalHours = 0;
    double totalExpenses = 0;

    final usersSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .get();

    for (final userDoc in usersSnap.docs) {
      for (final project in projects) {
        final logsSnap = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
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

  Future<Map<String, dynamic>> _getProjectTotals(String projectId) async {
    double totalHours = 0;
    double totalExpenses = 0;
    
    final usersSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .get();
        
    for (final userDoc in usersSnap.docs) {
      final logsSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userDoc.id)
          .collection('all_logs')
          .where('projectId', isEqualTo: projectId)
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client details card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? colors.cardColorDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF404040)
                      : colors.borderColorLight,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client name
                    Text(
                      client['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Info fields
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
                    const SizedBox(height: 10),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
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
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(AppLocalizations.of(context)!.edit),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: colors.whiteTextOnBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(
                            context,
                            widget.client['id'],
                            client['name'] ?? '',
                            widget.companyId,
                          ),
                          icon: Icon(
                            Icons.delete,
                            color: colors.error,
                            size: 20,
                          ),
                          tooltip: AppLocalizations.of(context)!.delete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                         ),
             const SizedBox(height: 20),
             // Projects section
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _projectsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colors.cardColorDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF404040)
                            : colors.borderColorLight,
                        width: 1,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final projects = snap.data ?? [];
                if (projects.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colors.cardColorDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF404040)
                            : colors.borderColorLight,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(AppLocalizations.of(context)!
                          .noProjectsFoundForThisClient),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Client totals summary
                    _ClientTotalsCard(
                      totals: _totalsFuture,
                    ),
                    const SizedBox(height: 10),
                    // Individual project cards
                    ...projects.map((project) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProjectCard(
                        project: project,
                        totals: _getProjectTotals(project['id']),
                      ),
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

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String clientId,
    String clientName,
    String companyId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${l10n.delete} ${l10n.client}',
            style: TextStyle(color: colors.primaryBlue),
          ),
          content: Text(
            l10n.confirmDeleteMessage.replaceAll('this user', '"$clientName"'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.whiteTextOnBlue,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteClient(context, clientId, companyId);
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteClient(
    BuildContext context,
    String clientId,
    String companyId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('${l10n.delete} ${l10n.client}...'),
            ],
          ),
        );
      },
    );

    try {
      // Delete the main client document
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('clients')
          .doc(clientId)
          .delete();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.client} ${l10n.deleteSuccessful}'),
            backgroundColor: colors.success,
          ),
        );
        
        // Navigate back to client list
        widget.onEdit();
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final Future<Map<String, dynamic>> totals;
  const _ProjectCard({
    required this.project,
    required this.totals,
  });

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
      future: totals,
      builder: (context, snap) {
        double hours = snap.data?['hours'] ?? 0;
        double expenses = snap.data?['expenses'] ?? 0;
        final hoursText = hours > 0 ? hours.toStringAsFixed(2) : '-';
        final expensesText =
            expenses > 0 ? '${expenses.toStringAsFixed(2)} CHF' : '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colors.cardColorDark
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF404040)
                  : colors.borderColorLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                    color: colors.textColor.withValues(alpha: 0.7),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colors.textColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textColor.withValues(alpha: 0.8),
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
                      color: colors.textColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalTime}: $hoursText',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.8),
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
                      color: colors.textColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalExpenses}: $expensesText',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.8),
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
  final Future<Map<String, dynamic>> totals;

  const _ClientTotalsCard({
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return FutureBuilder<Map<String, dynamic>>(
      future: totals,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.cardColorDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : colors.borderColorLight,
                width: 1,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final totals =
            snap.data ?? {'hours': 0.0, 'expenses': 0.0, 'projectCount': 0};
        final hours = totals['hours'] as double;
        final expenses = totals['expenses'] as double;
        final projectCount = totals['projectCount'] as int;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colors.cardColorDark
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF404040)
                  : colors.borderColorLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: colors.textColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.total} ${AppLocalizations.of(context)!.projects}: $projectCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.8),
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
                      color: colors.textColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalTime}: ${hours.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.8),
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
                      color: colors.textColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.totalExpenses}: ${expenses.toStringAsFixed(2)} CHF',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.8),
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
