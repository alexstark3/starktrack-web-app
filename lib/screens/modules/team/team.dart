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
    
    return Container(
      color: colors.backgroundDark,
      child: Column(
        children: [
          // --- Tab bar ---
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 25, right: 10), // Reduced right from 16 to 10
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showOnlyIcons = constraints.maxWidth < 600; // Show only icons on small screens
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Members tab
                    _TeamTab(
                      icon: Icons.group,
                      title: 'Members',
                      isSelected: _selectedIndex == 0,
                      colors: colors,
                      selectedMemberDoc: _selectedMemberDoc,
                      showOnlyIcon: showOnlyIcons,
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
                      showOnlyIcon: showOnlyIcons,
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
                      showOnlyIcon: showOnlyIcons,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2;
                          _selectedClient = null;
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
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10), // Reduced from 16 to 10
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Material(
                        elevation: Theme.of(context).brightness == Brightness.light ? 2 : 0,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? colors.cardColorDark 
                          : Colors.white,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10), // Reduced from 16 to 10
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
  final bool showOnlyIcon;
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
    this.showOnlyIcon = false,
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
              ? (isDark ? widget.colors.cardColorDark : Colors.white)
              : (_isHovered && isDark ? widget.colors.cardColorDark : (isDark ? widget.colors.dashboardBackground : widget.colors.dashboardBackground)),
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
                    ? (hasSelectedContent ? widget.colors.darkGray : widget.colors.primaryBlue)
                    : widget.colors.darkGray,
              ),
              if (!widget.showOnlyIcon) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
