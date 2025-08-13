part of 'members_view.dart';

class _TotalsHeader extends StatelessWidget {
  final String companyId;
  final String userId;

  const _TotalsHeader({required this.companyId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .collection('all_logs')
          .get(),
      builder: (context, snapshot) {
        double totalWork = 0;
        double totalExpenses = 0;
        int approvedCount = 0;
        int rejectedCount = 0;
        int pendingCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final workMinutes = (data['duration_minutes'] as int?) ?? 0;
            totalWork += workMinutes;

            final expenses = (data['expenses'] ?? {}) as Map<String, dynamic>;
            totalExpenses += expenses.values.fold<double>(
                0, (sum, e) => sum + (e is num ? e.toDouble() : 0));

            final approvedRaw = data['approved'];
            final rejectedRaw = data['rejected'];
            final approvedAfterEditRaw = data['approvedAfterEdit'];

            final isApproved =
                approvedRaw == true || approvedRaw == 1 || approvedRaw == '1';
            final isRejected =
                rejectedRaw == true || rejectedRaw == 1 || rejectedRaw == '1';
            final isApprovedAfterEdit = approvedAfterEditRaw == true ||
                approvedAfterEditRaw == 1 ||
                approvedAfterEditRaw == '1';

            if (isApprovedAfterEdit || isApproved) {
              approvedCount++;
            } else if (isRejected) {
              rejectedCount++;
            } else {
              pendingCount++;
            }
          }
        }

        return Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            Text(
                '${AppLocalizations.of(context)!.totalTime}: ${_fmtH(totalWork)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
                '${AppLocalizations.of(context)!.totalExpenses}: ${totalExpenses.toStringAsFixed(2)} CHF',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
                '${AppLocalizations.of(context)!.approved}: $approvedCount | ${AppLocalizations.of(context)!.rejected}: $rejectedCount | ${AppLocalizations.of(context)!.pending}: $pendingCount',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        );
      },
    );
  }
}
