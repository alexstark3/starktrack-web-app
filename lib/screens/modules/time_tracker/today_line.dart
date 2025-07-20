import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/l10n/app_localizations.dart';

class TodayLine extends StatefulWidget {
  const TodayLine({Key? key}) : super(key: key);

  @override
  State<TodayLine> createState() => _TodayLineState();
}

class _TodayLineState extends State<TodayLine> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? appColors.cardColorDark : theme.cardColor,
          border: isDark ? Border.all(color: const Color(0xFF404040), width: 1) : null,
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '${l10n.today}: ${DateFormat('dd MMM yyyy – HH:mm').format(_now)}',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: appColors.textColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
