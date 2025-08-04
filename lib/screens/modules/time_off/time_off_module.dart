import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'timeoff_calendar.dart';
import 'balance.dart';

class TimeOffModule extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffModule({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TimeOffModule> createState() => _TimeOffModuleState();
}

class _TimeOffModuleState extends State<TimeOffModule> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      color: colors.backgroundDark,
      child: Column(
        children: [
          // --- Tab bar ---
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 25, right: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showOnlyIcons = constraints.maxWidth < 600;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Calendar tab
                    _TimeOffTab(
                      icon: Icons.calendar_month,
                      title: 'Calendar',
                      isSelected: _selectedIndex == 0,
                      colors: colors,
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 0;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Balance tab
                    _TimeOffTab(
                      icon: Icons.balance,
                      title: 'Balance',
                      isSelected: _selectedIndex == 1,
                      colors: colors,
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
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
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
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
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
      return TimeOffCalendar(
        companyId: widget.companyId,
        userId: widget.userId,
      );
    } else if (_selectedIndex == 1) {
      return TimeOffBalance(
        companyId: widget.companyId,
        userId: widget.userId,
      );
    }
    return const SizedBox.shrink();
  }
}

// --- Time Off Tab Widget ---
class _TimeOffTab extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;
  final bool showOnlyIcon;

  const _TimeOffTab({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    this.showOnlyIcon = false,
  });

  @override
  State<_TimeOffTab> createState() => _TimeOffTabState();
}

class _TimeOffTabState extends State<_TimeOffTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    : widget.colors.dashboardBackground),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(6),
              bottom: Radius.circular(widget.isSelected ? 0 : 0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? widget.colors.primaryBlue
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
                        ? widget.colors.primaryBlue
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
