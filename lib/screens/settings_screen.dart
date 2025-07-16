import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final currentLang = themeProvider.language;

    const green = Color(0xFF3ECB68);
    const double labelWidth = 110;
    const double minGap = 50;
    const double tabWidth = 64;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorScheme.surfaceVariant.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle Row
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text('Dark mode', style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(width: minGap),
                SizedBox(
                  width: tabWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FlutterSwitch(
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Language Picker Row
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text('Language', style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(width: minGap),
                SizedBox(
                  width: tabWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButton<String>(
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
