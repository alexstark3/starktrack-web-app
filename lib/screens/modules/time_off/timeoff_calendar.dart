import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class TimeOffCalendar extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffCalendar({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TimeOffCalendar> createState() => _TimeOffCalendarState();
}

class _TimeOffCalendarState extends State<TimeOffCalendar> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Text(
        'Calendar functionality coming soon...',
        style: TextStyle(
          color: colors.textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
