import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class TimeOffBalance extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffBalance({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TimeOffBalance> createState() => _TimeOffBalanceState();
}

class _TimeOffBalanceState extends State<TimeOffBalance> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Text(
        'Balance functionality coming soon...',
        style: TextStyle(
          color: colors.textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
