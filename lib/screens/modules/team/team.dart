import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'members/members.dart';
import 'groups/groups.dart';
import 'balance/balance.dart';

class TeamModuleTabScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  final DocumentSnapshot? selectedMember; // Add selected member parameter
  final void Function(DocumentSnapshot? member)?
      onSelectMember; // Add callback parameter

  const TeamModuleTabScreen({
    super.key,
    required this.companyId,
    required this.userId,
    this.selectedMember,
    this.onSelectMember,
  });

  @override
  State<TeamModuleTabScreen> createState() => _TeamModuleTabScreenState();
}

class _TeamModuleTabScreenState extends State<TeamModuleTabScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.backgroundDark,
      child: Column(
        children: [
          // --- Tab bar ---
          Padding(
            padding: const EdgeInsets.only(
                top: 8, left: 25, right: 10), // Reduced right from 16 to 10
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showOnlyIcons = constraints.maxWidth <
                    600; // Show only icons on small screens

                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Members tab
                    _TeamTab(
                      icon: Icons.group,
                      title: l10n.members,
                      isSelected: _selectedIndex == 0,
                      colors: colors,
                      selectedMemberDoc:
                          widget.selectedMember, // Use widget parameter
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 0;
                          widget.onSelectMember
                              ?.call(null); // Clear via callback
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Groups tab
                    _TeamTab(
                      icon: Icons.groups,
                      title: 'Groups',
                      isSelected: _selectedIndex == 1,
                      colors: colors,
                      selectedMemberDoc: null,
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                          widget.onSelectMember?.call(null);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Balance tab
                    _TeamTab(
                      icon: Icons.balance,
                      title: 'Balance',
                      isSelected: _selectedIndex == 2,
                      colors: colors,
                      selectedMemberDoc: null,
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2;
                          widget.onSelectMember?.call(null);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // --- Main white area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, bottom: 10), // Reduced from 16 to 10
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Material(
                        elevation:
                            Theme.of(context).brightness == Brightness.light
                                ? 2
                                : 0,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colors.cardColorDark
                            : colors.backgroundLight,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                              10, 10, 10, 10), // Reduced from 16 to 10
                          child: _buildTabContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedIndex == 0) {
      return MembersTab(
        companyId: widget.companyId,
        teamLeaderId: null, // Show all users, not just team members
        selectedMember: widget.selectedMember, // Use widget parameter
        onSelectMember:
            widget.onSelectMember ?? (doc) {}, // Provide default callback
      );
    } else if (_selectedIndex == 1) {
      // Groups tab content
      return GroupsTab(
        companyId: widget.companyId,
      );
    } else if (_selectedIndex == 2) {
      // Balance tab content
      return BalanceTab(
        companyId: widget.companyId,
      );
    }
    return const SizedBox.shrink();
  }
}

// --- Team Tab Widget with isolated hover state ---
class _TeamTab extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;
  final DocumentSnapshot? selectedMemberDoc;
  final bool showOnlyIcon;
  const _TeamTab({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    this.selectedMemberDoc,
    this.showOnlyIcon = false,
  });

  @override
  State<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<_TeamTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine if tab has selected content
    final hasSelectedContent = widget.selectedMemberDoc != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? widget.colors.cardColorDark : Colors.white)
                : (_isHovered && isDark
                    ? widget.colors.cardColorDark
                    : (isDark
                        ? widget.colors.dashboardBackground
                        : widget.colors.dashboardBackground)),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(6),
              bottom: Radius.circular(widget.isSelected ? 0 : 0),
            ),
/*            boxShadow: !isDark && widget.isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                : null,
            border: isDark
                ? (widget.isSelected ? null : Border.all(color: const Color(0xFF2A2A2A), width: 1))
                : (widget.isSelected ? null : Border.all(color: Colors.black26, width: 1)),*/
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? (hasSelectedContent
                        ? widget.colors.darkGray
                        : widget.colors.primaryBlue)
                    : widget.colors.darkGray,
              ),
              if (!widget.showOnlyIcon) ...[
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        widget.isSelected ? FontWeight.bold : FontWeight.w600,
                    color: widget.isSelected
                        ? (hasSelectedContent
                            ? widget.colors.darkGray
                            : widget.colors.primaryBlue)
                        : widget.colors.darkGray,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
