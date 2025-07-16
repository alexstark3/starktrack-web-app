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
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Members tab
                      _TeamTab(
                        icon: Icons.group,
                        title: 'Members',
                        isSelected: _selectedIndex == 0,
                        colors: colors,
                        selectedMemberDoc: _selectedMemberDoc,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 0;
                            _selectedMemberDoc = null;
                          });
                        },
                      ),
                      // Projects tab
                      _TeamTab(
                        icon: Icons.folder_copy_rounded,
                        title: 'Projects',
                        isSelected: _selectedIndex == 1,
                        colors: colors,
                        selectedProject: _selectedProject,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                            _selectedProject = null;
                          });
                        },
                      ),
                      // Clients tab
                      _TeamTab(
                        icon: Icons.people_alt_rounded,
                        title: 'Clients',
                        isSelected: _selectedIndex == 2,
                        colors: colors,
                        selectedClient: _selectedClient,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                            _selectedClient = null;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // --- Main white area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: _NoTopShadowMaterial(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF252526) 
                        : Colors.white,
                      elevation: Theme.of(context).brightness == Brightness.light ? 8 : 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
                        margin: const EdgeInsets.only(top: 0),
                        child: _buildTabContent(),
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
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected 
              ? (isDark ? widget.colors.lightGray : const Color(0xFFF0F0F0))
              : (_isHovered && isDark ? const Color(0xFF252526) : (isDark ? widget.colors.dashboardBackground : widget.colors.lightGray)),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(6),
              bottom: Radius.circular(widget.isSelected ? 0 : 6),
            ),
            boxShadow: !isDark && widget.isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                : null,
            border: isDark
                ? Border.all(color: widget.isSelected ? const Color(0xFF404040) : const Color(0xFF2A2A2A), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? (hasSelectedContent ? widget.colors.darkGray : widget.colors.primaryBlue)
                    : widget.colors.darkGray,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  color: widget.isSelected
                      ? (hasSelectedContent ? widget.colors.darkGray : widget.colors.primaryBlue)
                      : widget.colors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
