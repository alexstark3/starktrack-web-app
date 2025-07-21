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
    const double minGap = 50;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: appColors.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).brightness == Brightness.dark 
            ? appColors.cardColorDark 
            : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle Row
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(l10n.darkMode, style: theme.textTheme.bodyLarge),
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
                      toggleColor: Theme.of(context).brightness == Brightness.dark 
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
                  child: Text(l10n.language, style: theme.textTheme.bodyLarge),
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
        ),
      ),
    );
  }
}
