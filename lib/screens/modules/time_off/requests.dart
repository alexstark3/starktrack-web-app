import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/widgets/app_search_field.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/l10n/app_localizations.dart';

class TimeOffRequests extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffRequests(
      {super.key, required this.companyId, required this.userId});

  @override
  State<TimeOffRequests> createState() => _TimeOffRequestsState();
}

class _TimeOffRequestsState extends State<TimeOffRequests> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        // Search + New Request button row
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hintText: AppLocalizations.of(context)!.searchRequests,
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () => _openNewRequestDialog(colors),
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.requestButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Requests list
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('timeoff_requests')
                .where('userId', isEqualTo: widget.userId)
                // Avoid composite-index requirement; client-side sort below
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        AppLocalizations.of(context)!.failedToLoadRequests));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Client-side sort by createdAt desc if present
              final docsList = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return tb.compareTo(ta);
                  }
                  return 0;
                });

              final docs = docsList.where((d) {
                if (_search.isEmpty) return true;
                final data = d.data();
                final hay = [
                  (data['policyName'] ?? '').toString(),
                  (data['status'] ?? '').toString(),
                  (data['description'] ?? '').toString(),
                ].join(' ').toLowerCase();
                return hay.contains(_search);
              }).toList();

              if (docs.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.noRequests));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final start = (data['startDate'] as Timestamp?)?.toDate();
                  final end = (data['endDate'] as Timestamp?)?.toDate();
                  final status = (data['status'] ?? 'pending') as String;

                  final dateText = start == null
                      ? ''
                      : end == null || end.isAtSameMomentAs(start)
                          ? DateFormat('dd/MM/yyyy').format(start)
                          : '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';

                  return ListTile(
                    title: Text(data['policyName'] ??
                        AppLocalizations.of(context)!.unknownPolicy),
                    subtitle: Text(dateText),
                    trailing: _statusChip(status, colors),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status, AppColors colors) {
    Color bg;
    Color fg;
    final l10n = AppLocalizations.of(context)!;
    String label;
    switch (status) {
      case 'approved':
        bg = colors.green;
        fg = Colors.white;
        label = l10n.approved;
        break;
      case 'rejected':
        bg = colors.red;
        fg = Colors.white;
        label = l10n.rejected;
        break;
      default:
        bg = colors.orange;
        fg = Colors.white;
        label = l10n.pending;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(label.toUpperCase(),
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Future<void> _openNewRequestDialog(AppColors colors) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewRequestDialog(
        companyId: widget.companyId,
        userId: widget.userId,
      ),
    );
  }
}

class _NewRequestDialog extends StatefulWidget {
  final String companyId;
  final String userId;
  const _NewRequestDialog({required this.companyId, required this.userId});

  @override
  State<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<_NewRequestDialog> {
  String? _selectedPolicyName;
  DateRange? _selectedRange;
  String _description = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.newTimeOffRequest,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor)),
            const SizedBox(height: 16),

            // Policy picker
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('timeoff_policies')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs
                    .map((d) => d.data())
                    .where((d) => (d['name'] as String?) != null)
                    .toList();
                items.sort((a, b) =>
                    (a['name'] as String).compareTo(b['name'] as String));

                return DropdownButtonFormField<String>(
                  value: _selectedPolicyName,
                  items: items
                      .map((p) => DropdownMenuItem<String>(
                            value: p['name'] as String,
                            child: Text(p['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPolicyName = v),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.policy,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Calendar for date range (matches Time Off filter styling)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () async {
                  final DateRange? range = await showDialog<DateRange>(
                    context: context,
                    builder: (context) => Dialog(
                      child: CustomCalendar(
                        initialDateRange: _selectedRange,
                        onDateRangeChanged: (r) {
                          setState(() => _selectedRange = r);
                        },
                        minDate: DateTime(2020),
                        maxDate: DateTime(2030),
                        showTodayIndicator: true,
                      ),
                    ),
                  );
                  if (range != null) setState(() => _selectedRange = range);
                },
                child: IntrinsicHeight(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    constraints: const BoxConstraints(minHeight: 38),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.darkGray.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 20, color: colors.darkGray),
                        const SizedBox(width: 8),
                        Text(
                          _formattedRangeText(),
                          style:
                              TextStyle(color: colors.textColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionOptional,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (v) => _description = v.trim(),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.whiteTextOnBlue,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.submitRequest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedPolicyName == null ||
        _selectedRange == null ||
        !_selectedRange!.isComplete) {
      return; // Could show a snackbar; keeping minimal per user preference
    }
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_requests')
          .add({
        'userId': widget.userId,
        'policyName': _selectedPolicyName,
        'status': 'pending',
        'startDate': Timestamp.fromDate(_selectedRange!.startDate!),
        'endDate': Timestamp.fromDate(_selectedRange!.endDate!),
        'description': _description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _submitting = false);
    }
  }
}

// Helper for date text formatting in the date field
extension on _NewRequestDialogState {
  String _formattedRangeText() {
    if (_selectedRange == null || !_selectedRange!.hasSelection) {
      return 'Pick dates';
    }
    final start = _selectedRange!.startDate;
    final end = _selectedRange!.endDate;
    if (start == null) return 'Pick dates';
    if (end == null || start.isAtSameMomentAs(end)) {
      return DateFormat('dd/MM/yyyy').format(start);
    }
    return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
  }
}
