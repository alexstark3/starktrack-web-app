// lib/screens/dashboard/company_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modules/time_tracker/time_tracker_screen.dart';
import '../modules/history/history.dart';
import '../modules/admin/admin_panel.dart';
import 'package:starktrack/screens/modules/team/team.dart'; // Team Module
import '../settings_screen.dart';
import 'package:starktrack/widgets/company/company_side_menu.dart';
import '../../widgets/company/company_top_bar.dart';
import 'package:starktrack/theme/app_colors.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.length >= 2
      ? (parts[0][0] + parts[1][0]).toUpperCase()
      : parts[0][0].toUpperCase();
}

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.roles,
    required this.access,
    required this.fullName,
    required this.email,
  });

  final String companyId, userId, fullName, email;
  final List<String> roles;
  final Map<String, dynamic> access;

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  late String _selected;
  late final List<_ScreenCfg> _screenConfigs;
  late final List<String> _tabLabels;

  @override
  void initState() {
    super.initState();
    _screenConfigs = _screens;
    _tabLabels = _screenConfigs.map((s) => s.label).toList();
    _selected = _tabLabels.first;
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.fullName);
    final colors   = Theme.of(context).extension<AppColors>()!;

    // rail width depends on compact
    final bool compact = MediaQuery.of(context).size.width < 600;
    final double railWidth = compact ? 72 : 220;
    final double barHeight = CompanyTopBar.kHeight;

    // --- IndexedStack for persistent tab state ---
    final body = Container(
      color: colors.dashboardBackground,
      child: IndexedStack(
        index: _tabLabels.indexOf(_selected),
        children: [
          if (_tabLabels.contains('Time Tracker'))
            TimeTrackerScreen(
              key: const PageStorageKey('tracker'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (_tabLabels.contains('History'))
            HistoryLogs(
              key: const PageStorageKey('history'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (_tabLabels.contains('Team'))
            TeamModuleTabScreen(
              key: const PageStorageKey('team'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (_tabLabels.contains('Admin'))
            AdminPanel(
              key: const PageStorageKey('admin'),
              companyId: widget.companyId,
              currentUserRoles: widget.roles,
            ),
          if (_tabLabels.contains('Settings'))
            const SettingsScreen(key: PageStorageKey('settings')),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // ── Layer 1: body + padding for rail & bar ──
          Padding(
            padding: EdgeInsets.only(left: railWidth, top: barHeight),
            child: body,
          ),

          // ── Layer 2: side-rail on top with elevation ──
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: railWidth,
            child: CompanySideMenu(
              menuItems: _screenConfigs
                  .map((s) => SideMenuItem(
                        label   : s.label,
                        icon    : s.icon,
                        selected: _selected == s.label,
                        onTap   : () => setState(() => _selected = s.label),
                      ))
                  .toList(),
              compact: compact,
              showBrand: true,
            ),
          ),

          // ── Layer 3: top-bar floats above content to right of rail ──
          Positioned(
            top: 0,
            left: railWidth,
            right: 0,
            child: CompanyTopBar(
              screenTitle:   _selected,
              fullName:      widget.fullName,
              email:         widget.email,
              initials:      initials,
              selectedScreen: _selected,
              onSettings:    () => setState(() => _selected = 'Settings'),
              onLogout: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_ScreenCfg> get _screens {
    final l = <_ScreenCfg>[];
    if (widget.access['time_tracker'] == true) {
      l.add(_ScreenCfg('Time Tracker', Icons.access_time));
      l.add(_ScreenCfg('History',      Icons.history));
    }
    // TEAM MODULE: Only for roles company_admin, admin, team_leader
    if (widget.roles.contains('company_admin') ||
        widget.roles.contains('admin') ||
        widget.roles.contains('team_leader')) {
      l.add(_ScreenCfg('Team', Icons.group));
    }
    if (widget.roles.contains('admin') || widget.roles.contains('company_admin')) {
      l.add(_ScreenCfg('Admin', Icons.admin_panel_settings));
    }
    l.add(_ScreenCfg('Settings', Icons.settings));
    return l;
  }
}

class _ScreenCfg {
  final String label;
  final IconData icon;
  const _ScreenCfg(this.label, this.icon);
}
