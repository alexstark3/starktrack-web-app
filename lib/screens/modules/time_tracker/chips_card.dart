import 'package:flutter/material.dart';
import 'package:starktrack/theme/app_colors.dart';

class ChipsCard extends StatelessWidget {
  final Duration worked;
  final Duration breaks;

  const ChipsCard({
    Key? key,
    required this.worked,
    required this.breaks,
  }) : super(key: key);

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '00:00h';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m' + 'h';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Main card shadow
    final cardShadow = [
      BoxShadow(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.2),
        blurRadius: 1,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

    // Chips shadow
    final chipShadow = [
      BoxShadow(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.2),
        blurRadius: 1,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

    final chipBorder = Border.all(
      color: appColors.darkGray.withOpacity(0.2),
      width: 1,
    );

    TextStyle chipStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      color: appColors.textColor,
    );

    Widget buildChip(String text) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: chipShadow,
          border: chipBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: chipStyle),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
        boxShadow: cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildChip('Worked: ${_formatDuration(worked)}'),
            const SizedBox(width: 10),
            buildChip('Breaks: ${_formatDuration(breaks)}'),
          ],
        ),
      ),
    );
  }
}
