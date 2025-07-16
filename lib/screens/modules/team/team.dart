import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import 'members/members.dart';
import 'projects/projects.dart';
import 'clients/clients.dart';

class TeamModuleTabScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  const TeamModuleTabScreen({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TeamModuleTabScreen> createState() => _TeamModuleTabScreenState();
}

class _TeamModuleTabScreenState extends State<TeamModuleTabScreen> {
  int _selectedIndex = 0;

  DocumentSnapshot? _selectedMemberDoc;
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedClient; // <-- Add client selection

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: colors.dashboardBackground,
      child: Column(
        children: [
          // --- Tab bar ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 13, right: 24, top: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if we have enough space for horizontal layout
                final tabWidth = 120.0; // Approximate width per tab
                final totalTabWidth = tabWidth * 3 + 16; // 3 tabs + spacing
                final useHorizontalLayout = constraints.maxWidth > totalTabWidth;
                
                if (useHorizontalLayout) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TeamTab(
                        icon: Icons.group,
                        title: 'Members',
                        isSelected: _selectedIndex == 0,
                        colors: colors,
                        selectedMemberDoc: _selectedMemberDoc,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _TeamTab(
                        icon: Icons.work,
                        title: 'Projects',
                        isSelected: _selectedIndex == 1,
                        colors: colors,
                        selectedProject: _selectedProject,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _TeamTab(
                        icon: Icons.business,
                        title: 'Clients',
                        isSelected: _selectedIndex == 2,
                        colors: colors,
                        selectedClient: _selectedClient,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                    ],
                  );
                } else {
                  // Vertical stacked layout for small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TeamTab(
                        icon: Icons.group,
                        title: 'Members',
                        isSelected: _selectedIndex == 0,
                        colors: colors,
                        selectedMemberDoc: _selectedMemberDoc,
                        onTap: () => setState(() => _selectedIndex = 0),
                        isStacked: true,
                      ),
                      _TeamTab(
                        icon: Icons.work,
                        title: 'Projects',
                        isSelected: _selectedIndex == 1,
                        colors: colors,
                        selectedProject: _selectedProject,
                        onTap: () => setState(() => _selectedIndex = 1),
                        isStacked: true,
                      ),
                      _TeamTab(
                        icon: Icons.business,
                        title: 'Clients',
                        isSelected: _selectedIndex == 2,
                        colors: colors,
                        selectedClient: _selectedClient,
                        onTap: () => setState(() => _selectedIndex = 2),
                        isStacked: true,
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          
          // --- Content area ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D30) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: _buildTabContent(),
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
        teamLeaderId: widget.userId,
        selectedMember: _selectedMemberDoc,
        onSelectMember: (doc) {
          setState(() {
            _selectedMemberDoc = doc;
          });
        },
      );
    } else if (_selectedIndex == 1) {
      return ProjectsTab(
        companyId: widget.companyId,
        selectedProject: _selectedProject,
        onSelectProject: (project) {
          setState(() {
            _selectedProject = project;
          });
        },
      );
    } else if (_selectedIndex == 2) {
  // --- Clients logic with tab navigation and detail view ---
  return ClientsTab(
    companyId: widget.companyId,
    selectedClient: _selectedClient,
    onSelectClient: (Map<String, dynamic>? clientData) { // <-- now nullable!
      setState(() {
        if (clientData == null || clientData['id'] == null || clientData.isEmpty) {
          _selectedClient = null;
        } else {
          _selectedClient = clientData;
        }
      });
    },
  );
}
    return const SizedBox.shrink();
  }
}

// --- Helper for shadowed white card, no shadow on top ---
class _NoTopShadowMaterial extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final double elevation;

  const _NoTopShadowMaterial({
    required this.child,
    required this.color,
    required this.borderRadius,
    this.elevation = 6,
  });

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      elevation: elevation,
      clipper: _BottomOnlyClipper(borderRadius),
      color: color,
      shadowColor: Colors.black12,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

class _BottomOnlyClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;
  _BottomOnlyClipper(this.borderRadius);

  @override
  Path getClip(Size size) {
    return Path()
      ..addRRect(borderRadius.toRRect(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldReclip(_BottomOnlyClipper oldClipper) => false;
}

// --- Team Tab Widget with isolated hover state ---
class _TeamTab extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;
  final DocumentSnapshot? selectedMemberDoc;
  final Map<String, dynamic>? selectedProject;
  final Map<String, dynamic>? selectedClient;
  final bool isStacked;

  const _TeamTab({
    Key? key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    this.selectedMemberDoc,
    this.selectedProject,
    this.selectedClient,
    this.isStacked = false,
  }) : super(key: key);

  @override
  State<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<_TeamTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine if tab has selected content
    final hasSelectedContent = widget.selectedMemberDoc != null || 
                              widget.selectedProject != null || 
                              widget.selectedClient != null;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: widget.isStacked 
            ? const EdgeInsets.only(bottom: 2)
            : const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected 
              ? (isDark ? const Color(0xFF2D2D30) : Colors.white)
              : (_isHovered 
                  ? (isDark ? const Color(0xFF252526) : const Color(0xFFF5F5F5))
                  : (isDark ? widget.colors.dashboardBackground : const Color(0xFFE8E8E8))),
            borderRadius: widget.isStacked
              ? (widget.isSelected 
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    )
                  : BorderRadius.circular(8))
              : (widget.isSelected 
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    )
                  : BorderRadius.circular(8)),
            boxShadow: !isDark && widget.isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
            border: widget.isSelected
                ? null
                : Border.all(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFD0D0D0), 
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? (hasSelectedContent 
                        ? (isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A))
                        : widget.colors.primaryBlue)
                    : (isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A)),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  color: widget.isSelected
                      ? (hasSelectedContent 
                          ? (isDark ? const Color(0xFFCCCCCC) : Colors.black87)
                          : widget.colors.primaryBlue)
                      : (isDark ? const Color(0xFF969696) : const Color(0xFF6A6A6A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
