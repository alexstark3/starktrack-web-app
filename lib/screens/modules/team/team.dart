import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _selectedProject;

  final List<String> _folders = ['Members', 'Projects', 'Clients'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bool inProjectView = _selectedIndex == 1 && _selectedProject != null;

    return Container(
      color: colors.dashboardBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 54, right: 24),
            child: Row(
              children: List.generate(_folders.length, (index) {
                final isSelected = _selectedIndex == index;
                final icon = index == 0
                    ? Icons.group
                    : index == 1
                        ? Icons.folder_copy_rounded
                        : Icons.people_alt_rounded;
                final isProjectViewGray =
                    (index == 1 && inProjectView); // Only gray text if in project view
                return GestureDetector(
                  onTap: () {
                    if (index == 1) {
                      if (inProjectView) {
                        setState(() => _selectedProject = null);
                      } else {
                        setState(() => _selectedIndex = 1);
                      }
                    } else {
                      setState(() => _selectedIndex = index);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: EdgeInsets.only(right: 16),
                    padding: EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : colors.lightGray,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6),
                        bottom: Radius.circular(isSelected ? 0 : 6),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isProjectViewGray
                              ? colors.darkGray
                              : (isSelected ? colors.primaryBlue : colors.darkGray),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _folders[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isProjectViewGray
                                ? colors.darkGray
                                : (isSelected ? colors.primaryBlue : colors.darkGray),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: _NoTopShadowMaterial(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      color: Colors.white,
                      elevation: 10,
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
    switch (_selectedIndex) {
      case 0:
        return MembersTab(
            companyId: widget.companyId, teamLeaderId: widget.userId);
      case 1:
        return ProjectsTab(
          companyId: widget.companyId,
          selectedProject: _selectedProject,
          onSelectProject: (project) {
            setState(() => _selectedProject = project);
          },
        );
      case 2:
        return ClientsTab(companyId: widget.companyId);
      default:
        return SizedBox.shrink();
    }
  }
}

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
