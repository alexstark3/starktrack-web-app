import 'package:flutter/material.dart';

class CompanyTopBar extends StatelessWidget {
  static const double kHeight = 56;

  final String screenTitle;
  final String fullName;
  final String email;
  final String initials;
  final String selectedScreen;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const CompanyTopBar({
    super.key,
    required this.screenTitle,
    required this.fullName,
    required this.email,
    required this.initials,
    required this.selectedScreen,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(                       // separate layer ⇒ guaranteed shadow
      elevation: 6,                        // ← try 3-4 dp: clearly visible
      color: theme.colorScheme.background, // bar colour
      shadowColor:
          Colors.black.withOpacity(0.4),  // subtle but visible on white
      child: SizedBox(
        height: kHeight,
        child: Row(
          children: [
            /* ─ screen title ─ */
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    screenTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            /* ─ square avatar & popup ─ */
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                tooltip: 'Account',
                offset: const Offset(0, kHeight),
                splashRadius: 20,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    value: 'info',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(
                    height: 1,
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: const Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                    onTap: onSettings,
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Log out'),
                      ],
                    ),
                    onTap: onLogout,
                  ),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,   // blue
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
