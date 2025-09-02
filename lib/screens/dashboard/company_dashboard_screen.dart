// lib/screens/dashboard/company_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/time_tracker/time_tracker_screen.dart';
import '../modules/history/history.dart';
import '../modules/time_off/time_off_module.dart';
import '../modules/team/team.dart'; // Team Module
import 'package:starktrack/screens/modules/projects/projects.dart'; // Projects Module
import 'package:starktrack/screens/modules/clients/clients.dart'; // Clients Module
import '../modules/admin/admin_panel.dart';
import '../modules/reports/reports.dart';
import '../settings_screen.dart';
import 'package:starktrack/widgets/company/company_side_menu.dart';
import '../../widgets/company/company_top_bar.dart';
import 'package:starktrack/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedClient;
  DocumentSnapshot?
      _selectedMember; // Add selected member state like projects/clients

  @override
  void initState() {
    super.initState();
    // Initialize with default values, will be updated in build method
    _selected = 'Time Tracker'; // Default, will be updated
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.fullName);
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    // Update screen configs and labels in build method when context is available
    final screenConfigs = _getScreens(l10n);
    final tabLabels = screenConfigs.map((s) => s.label).toList();

    // Ensure selected is always valid
    if (!tabLabels.contains(_selected) || tabLabels.isEmpty) {
      _selected = tabLabels.isNotEmpty ? tabLabels.first : '';
    }

    // rail width depends on compact
    final bool compact = MediaQuery.of(context).size.width < 600;
    final double railWidth = compact
        ? 56
        : 220; // Increased from 40 to 56 to accommodate bigger icons
    final double barHeight = CompanyTopBar.kHeight;

    // --- IndexedStack for persistent tab state ---
    final body = Container(
      color: colors.dashboardBackground,
      child: IndexedStack(
        index: tabLabels.isNotEmpty
            ? tabLabels.indexOf(_selected).clamp(0, tabLabels.length - 1)
            : 0,
        children: [
          if (tabLabels.contains(l10n.timeTracker))
            TimeTrackerScreen(
              key: const PageStorageKey('tracker'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (tabLabels.contains(l10n.history))
            HistoryLogs(
              key: const PageStorageKey('history'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (tabLabels.contains(l10n.timeOff))
            TimeOffModule(
              key: const PageStorageKey('timeOff'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (tabLabels.contains(l10n.team))
            TeamModuleTabScreen(
              key: const PageStorageKey('team'),
              companyId: widget.companyId,
              userId: widget.userId,
              selectedMember: _selectedMember, // Pass selected member
              onSelectMember: (member) {
                // Add callback like projects/clients
                setState(() {
                  _selectedMember = member;
                });
              },
            ),
          if (tabLabels.contains(l10n.projects))
            ProjectsTab(
              key: const PageStorageKey('projects'),
              companyId: widget.companyId,
              selectedProject: _selectedProject,
              onSelectProject: (project) {
                setState(() {
                  _selectedProject = project;
                });
              },
            ),
          if (tabLabels.contains(l10n.clients))
            ClientsTab(
              key: const PageStorageKey('clients'),
              companyId: widget.companyId,
              selectedClient: _selectedClient,
              onSelectClient: (client) {
                setState(() {
                  _selectedClient = client;
                });
              },
            ),
          if (tabLabels.contains(l10n.reports))
            ReportsScreen(
              key: const PageStorageKey('reports'),
              companyId: widget.companyId,
              userId: widget.userId,
            ),
          if (tabLabels.contains(l10n.admin))
            AdminPanel(
              key: const PageStorageKey('admin'),
              companyId: widget.companyId,
              currentUserRoles: widget.roles,
            ),
          if (tabLabels.contains(l10n.settings))
            const SettingsScreen(key: PageStorageKey('settings')),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).extension<AppColors>()!.backgroundDark,
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
              menuItems: screenConfigs
                  .map((s) => SideMenuItem(
                        label: s.label,
                        icon: s.icon,
                        selected: _selected == s.label,
                        onTap: () => setState(() {
                          _selected = s.label;
                          // Clear selected project/client when clicking on their respective tabs
                          if (s.label == l10n.projects) {
                            _selectedProject =
                                null; // Clear when clicking Projects tab
                          }
                          if (s.label == l10n.clients) {
                            _selectedClient =
                                null; // Clear when clicking Clients tab
                          }
                          if (s.label == l10n.team) {
                            _selectedMember =
                                null; // Clear when clicking Team tab - same pattern as projects/clients
                          }
                        }),
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
              screenTitle: _selected,
              fullName: widget.fullName,
              email: widget.email,
              initials: initials,
              selectedScreen: _selected,
              onSettings: () => setState(() => _selected = l10n.settings),
              onLogout: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_ScreenCfg> _getScreens(AppLocalizations l10n) {
    final l = <_ScreenCfg>[];
    // Time Tracker should be available to all users
    l.add(_ScreenCfg(l10n.timeTracker, Icons.access_time));
    l.add(_ScreenCfg(l10n.history, Icons.history));
    
    // TIME OFF MODULE: Only show if user has time_off module enabled
    if (widget.access['time_off'] == true) {
      l.add(_ScreenCfg(l10n.timeOff, Icons.calendar_month));
    }

    // TEAM MODULE: Only show if company has team module AND user has required role
    if (widget.access['team'] == true &&
        (widget.roles.contains('company_admin') ||
         widget.roles.contains('admin') ||
         widget.roles.contains('team_leader'))) {
      l.add(_ScreenCfg(l10n.team, Icons.group));
    }
    
    // PROJECTS MODULE: Only show if company has projects module AND user has required role
    if (widget.access['projects'] == true &&
        (widget.roles.contains('company_admin') ||
         widget.roles.contains('admin') ||
         widget.roles.contains('team_leader'))) {
      l.add(_ScreenCfg(l10n.projects, Icons.folder));
    }
    
    // CLIENTS MODULE: Only show if company has clients module AND user has required role
    if (widget.access['clients'] == true &&
        (widget.roles.contains('company_admin') ||
         widget.roles.contains('admin') ||
         widget.roles.contains('team_leader'))) {
      l.add(_ScreenCfg(l10n.clients, Icons.business));
    }
    
    // REPORTS MODULE: Only show if company has reports module AND user has required role
    if (widget.access['reports'] == true &&
        (widget.roles.contains('company_admin') ||
         widget.roles.contains('admin') ||
         widget.roles.contains('team_leader'))) {
      l.add(_ScreenCfg(l10n.reports, Icons.assessment));
    }
    
    // ADMIN MODULE: Only show if company has admin module AND user has required role
    if (widget.access['admin'] == true &&
        (widget.roles.contains('admin') ||
         widget.roles.contains('company_admin'))) {
      l.add(_ScreenCfg(l10n.admin, Icons.admin_panel_settings));
    }
    
    l.add(_ScreenCfg(l10n.settings, Icons.settings));
    return l;
  }
}

class _ScreenCfg {
  final String label;
  final IconData icon;
  const _ScreenCfg(this.label, this.icon);
}
