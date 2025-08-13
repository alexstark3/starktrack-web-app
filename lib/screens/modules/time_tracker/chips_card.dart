import 'package:flutter/material.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/l10n/app_localizations.dart';

class ChipsCard extends StatelessWidget {
  final Duration worked;
  final Duration breaks;
  final bool showBreaks; // <-- NEW

  const ChipsCard({
    super.key,
    required this.worked,
    required this.breaks,
    this.showBreaks = true, // default to true for backwards compatibility
  });

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '00:00h';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m' + 'h';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Solid colors for dark theme
    final cardColor =
        isDark ? appColors.cardColorDark : Theme.of(context).cardColor;

    final chipBorder = Border.all(
      color: appColors.darkGray.withValues(alpha: 0.2),
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
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(color: const Color(0xFF404040), width: 1)
              : chipBorder,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        border: isDark
            ? Border.all(color: const Color(0xFF404040), width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isVerySmall = screenWidth < 400; // Breakpoint for wrapping

            if (isVerySmall) {
              // Very small screens: stack chips vertically
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildChip('${l10n.worked}: ${_formatDuration(worked)}'),
                  if (showBreaks) ...[
                    const SizedBox(height: 8),
                    buildChip('${l10n.breaks}: ${_formatDuration(breaks)}'),
                  ],
                ],
              );
            } else {
              // Normal screens: chips in a row
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildChip('${l10n.worked}: ${_formatDuration(worked)}'),
                  if (showBreaks) ...[
                    const SizedBox(width: 10),
                    buildChip('${l10n.breaks}: ${_formatDuration(breaks)}'),
                  ],
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
