import 'package:flutter/material.dart';
import 'package:starktrack/theme/app_colors.dart';

class ChipsCard extends StatelessWidget {
  final Duration worked;
  final Duration breaks;
  final bool showBreaks; // <-- NEW

  const ChipsCard({
    Key? key,
    required this.worked,
    required this.breaks,
    this.showBreaks = true, // default to true for backwards compatibility
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

    // Gradient colors for dark theme
    final gradientColors = isDark 
      ? [const Color(0xFF404040), const Color(0xFF2D2D2D)]
      : [const Color(0xFFF8F8F8), const Color(0xFFF0F0F0)];

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
          gradient: isDark ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ) : null,
          color: isDark ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isDark ? Border.all(color: const Color(0xFF505050), width: 1) : chipBorder,
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: chipStyle),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isDark ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ) : null,
        color: isDark ? null : Theme.of(context).cardColor,
        border: isDark ? Border.all(color: const Color(0xFF505050), width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildChip('Worked: ${_formatDuration(worked)}'),
            if (showBreaks) ...[
              const SizedBox(width: 10),
              buildChip('Breaks: ${_formatDuration(breaks)}'),
            ],
          ],
        ),
      ),
    );
  }
}
