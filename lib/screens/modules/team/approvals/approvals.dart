import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/l10n/app_localizations.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/widgets/app_search_field.dart';

class TeamApprovalsScreen extends StatefulWidget {
  final String companyId;
  const TeamApprovalsScreen({super.key, required this.companyId});

  @override
  State<TeamApprovalsScreen> createState() => _TeamApprovalsScreenState();
}

class _TeamApprovalsScreenState extends State<TeamApprovalsScreen> {
  String _search = '';
  String _statusFilter = 'all'; // default to all

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              // Search (standardized single field without extra wrapper borders)
              Expanded(
                child: AppSearchField(
                  hintText: AppLocalizations.of(context)!.searchRequests,
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 10),
              // Status filter
              SizedBox(
                height: 38,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      items: [
                        DropdownMenuItem(
                            value: 'pending',
                            child: Text(AppLocalizations.of(context)!.pending)),
                        DropdownMenuItem(
                            value: 'approved',
                            child:
                                Text(AppLocalizations.of(context)!.approved)),
                        DropdownMenuItem(
                            value: 'rejected',
                            child:
                                Text(AppLocalizations.of(context)!.rejected)),
                        DropdownMenuItem(
                            value: 'all',
                            child: Text(AppLocalizations.of(context)!.all)),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('timeoff_requests')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.error));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs.where((d) {
                final data = d.data();
                final status = (data['status'] ?? 'pending').toString();
                if (_statusFilter != 'all' && status != _statusFilter) {
                  return false;
                }
                if (_search.isEmpty) {
                  return true;
                }
                final hay = [
                  (data['policyName'] ?? '').toString(),
                  status,
                  (data['description'] ?? '').toString(),
                  (data['userId'] ?? '').toString(),
                ].join(' ').toLowerCase();
                return hay.contains(_search);
              }).toList()
                ..sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return tb.compareTo(ta);
                  }
                  return 0;
                });

              if (docs.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.noRequests));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final ref = docs[i].reference;
                  final data = docs[i].data();
                  final start = (data['startDate'] as Timestamp?)?.toDate();
                  final end = (data['endDate'] as Timestamp?)?.toDate();
                  final status = (data['status'] ?? 'pending') as String;
                  final dateText = start == null
                      ? ''
                      : end == null || start.isAtSameMomentAs(end)
                          ? DateFormat('dd/MM/yyyy').format(start)
                          : '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';

                  return ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(data['policyName'] ??
                        AppLocalizations.of(context)!.unknownPolicy),
                    subtitle: Text(dateText),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == 'pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            tooltip: AppLocalizations.of(context)!.approve,
                            onPressed: () => _updateStatus(ref, 'approved'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            tooltip: AppLocalizations.of(context)!.edit,
                            onPressed: () => _editDates(ref, start, end),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: AppLocalizations.of(context)!.deny,
                            onPressed: () => _denyWithNote(ref),
                          ),
                        ] else ...[
                          _statusChip(status,
                              Theme.of(context).extension<AppColors>()!),
                        ]
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
      DocumentReference<Map<String, dynamic>> ref, String status) async {
    await ref
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _editDates(DocumentReference<Map<String, dynamic>> ref,
      DateTime? start, DateTime? end) async {
    DateRange? range = DateRange(startDate: start, endDate: end);
    final DateRange? picked = await showDialog<DateRange>(
      context: context,
      builder: (context) => Dialog(
        child: CustomCalendar(
          initialDateRange: range,
          onDateRangeChanged: (r) => range = r,
          minDate: DateTime(2020),
          maxDate: DateTime(2030),
          showTodayIndicator: true,
        ),
      ),
    );
    if (picked != null && picked.isComplete) {
      await ref.update({
        'startDate': Timestamp.fromDate(picked.startDate!),
        'endDate': Timestamp.fromDate(picked.endDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _denyWithNote(
      DocumentReference<Map<String, dynamic>> ref) async {
    final TextEditingController ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.denyRequest),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.descriptionOptional),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.red, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.deny),
            )
          ],
        );
      },
    );
    if (ok == true) {
      await ref.update({
        'status': 'rejected',
        'reviewNote': ctrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _statusChip(String status, AppColors colors) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = colors.green;
        fg = Colors.white;
        break;
      case 'rejected':
        bg = colors.red;
        fg = Colors.white;
        break;
      default:
        bg = colors.orange;
        fg = Colors.white;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(status.toUpperCase(),
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
