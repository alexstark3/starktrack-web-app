import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/company/company_side_menu.dart';
import '../../widgets/company/company_top_bar.dart';
import '../modules/time_tracker_screen.dart';
import '../admin/admin_panel.dart';
import '../settings_screen.dart';
import 'package:starktrack/theme/app_colors.dart';

// Util for initials (GP for Goran Petrov)
String getInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return '?';
}

class CompanyDashboardScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  final List<String> roles;
  final Map<String, dynamic> access;
  final String fullName;
  final String email;

  const CompanyDashboardScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.roles,
    required this.access,
    required this.fullName,
    required this.email,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  late String selectedScreen;

  @override
  void initState() {
    super.initState();
    final available = _availableScreens();
    selectedScreen = available.isNotEmpty ? available.first.label : 'Access Denied';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Choose background color for main area depending on theme
    final dashboardBgColor = Theme.of(context).extension<AppColors>()!.dashboardBackground;

    final allScreens = <String, Widget>{
      'Time Tracker': TimeTrackerScreen(
        companyId: widget.companyId,
        userId: widget.userId,
      ),
      'Admin': AdminPanel(companyId: widget.companyId),
      'Settings': const SettingsScreen(),
    };

    final availableScreens = _availableScreens();
    final selectedWidget = allScreens[selectedScreen] ??
        const Center(child: Text('Screen Not Found'));

    final initials = getInitials(widget.fullName);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Top Bar (white or black only)
          CompanyTopBar(
            fullName: widget.fullName,
            email: widget.email,
            initials: initials,
            selectedScreen: selectedScreen,
            onSettings: () {
              setState(() {
                selectedScreen = 'Settings';
              });
            },
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          Expanded(
            child: Row(
              children: [
                // Sidebar (white or black only)
                Container(
                  color: colorScheme.background,
                  child: CompanySideMenu(
                    menuItems: availableScreens.map((item) {
                      return SideMenuItem(
                        label: item.label,
                        icon: item.icon,
                        selected: selectedScreen == item.label,
                        onTap: () => setState(() => selectedScreen = item.label),
                      );
                    }).toList(),
                  ),
                ),
                // Main content (gray or dark gray)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: dashboardBgColor,
                    child: selectedWidget,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_ScreenConfig> _availableScreens() {
    final List<_ScreenConfig> screens = [];

    if (widget.access['time_tracker'] == true) {
      screens.add(_ScreenConfig('Time Tracker', Icons.access_time));
    }
    if (widget.roles.contains('admin')) {
      screens.add(_ScreenConfig('Admin', Icons.admin_panel_settings));
    }
    screens.add(_ScreenConfig('Settings', Icons.settings));
    return screens;
  }
}

class _ScreenConfig {
  final String label;
  final IconData icon;

  _ScreenConfig(this.label, this.icon);
}
