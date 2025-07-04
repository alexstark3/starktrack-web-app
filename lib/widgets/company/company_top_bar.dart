import 'package:flutter/material.dart';

class CompanyTopBar extends StatelessWidget {
  static const double sideMenuWidth = 220; // must match sidebar

  final String fullName;
  final String email;
  final String initials; // This should now be built using getInitials below!
  final String selectedScreen;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const CompanyTopBar({
    super.key,
    required this.fullName,
    required this.email,
    required this.initials,
    required this.selectedScreen,
    required this.onSettings,
    required this.onLogout,
  });

  // Place this function in your dashboard or wherever you build the initials to pass here
  static String getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const double reserved = sideMenuWidth - 16; // 16 px row padding

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // reserve width & centre brand
          SizedBox(
            width: reserved,
            child: Align(
              alignment: Alignment.center,
              child: const Text(
                'Stark Track',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // divider on sidebar edge
          SizedBox(
            height: 24,
            width: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.dividerColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(selectedScreen, style: theme.textTheme.titleMedium),
          const Spacer(),
          // avatar w/ menu
          PopupMenuButton<int>(
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            splashRadius: 20,
            onSelected: (v) => v == 0 ? onSettings() : onLogout(),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName.isNotEmpty ? fullName : 'Unknown user',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(email, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: const [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                initials, // <-- should be "GP" for "Goran Petrov"
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
