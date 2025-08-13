import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final currentLang = themeProvider.language;
    final l10n = AppLocalizations.of(context)!;

    const green = Color(0xFF3ECB68);
    const double labelWidth = 110;
    const double minGap = 16;

    return Scaffold(
      backgroundColor: appColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings field card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : appColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dark Mode Toggle Row
                  Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(l10n.darkMode,
                            style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: minGap),
                      FlutterSwitch(
                        width: 48,
                        height: 28,
                        toggleSize: 20,
                        borderRadius: 20,
                        padding: 3,
                        activeColor: green,
                        inactiveColor: Colors.black,
                        toggleColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                        value: isDark,
                        onToggle: (_) => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Language Picker Row
                  Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(l10n.language,
                            style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: minGap),
                      DropdownButton<String>(
                        value: currentLang,
                        underline: Container(),
                        alignment: AlignmentDirectional.centerStart,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'EN', child: Text('EN')),
                          DropdownMenuItem(value: 'DE', child: Text('DE')),
                          DropdownMenuItem(value: 'FR', child: Text('FR')),
                          DropdownMenuItem(value: 'IT', child: Text('IT')),
                        ],
                        onChanged: (lang) {
                          if (lang != null) {
                            themeProvider.setLanguage(lang);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
