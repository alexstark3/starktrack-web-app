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
      color: colors.dashboardBackground,
      child: Column(
        children: [
          // --- Tab bar ---
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 54, right: 24),
            child: Row(
              children: [
                // Members tab
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                      _selectedMemberDoc = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0 ? Colors.white : colors.lightGray,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(6),
                        bottom: Radius.circular(_selectedIndex == 0 ? 0 : 6),
                      ),
                      boxShadow: _selectedIndex == 0
                          ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group,
                            size: 20,
                            color: _selectedIndex == 0
                                ? (_selectedMemberDoc == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray),
                        const SizedBox(width: 8),
                        Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.w600,
                            color: _selectedIndex == 0
                                ? (_selectedMemberDoc == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Projects tab
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                      _selectedProject = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1 ? Colors.white : colors.lightGray,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(6),
                        bottom: Radius.circular(_selectedIndex == 1 ? 0 : 6),
                      ),
                      boxShadow: _selectedIndex == 1
                          ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_copy_rounded,
                            size: 20,
                            color: _selectedIndex == 1
                                ? (_selectedProject == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray),
                        const SizedBox(width: 8),
                        Text(
                          'Projects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.w600,
                            color: _selectedIndex == 1
                                ? (_selectedProject == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Clients tab
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                      _selectedClient = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 2 ? Colors.white : colors.lightGray,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(6),
                        bottom: Radius.circular(_selectedIndex == 2 ? 0 : 6),
                      ),
                      boxShadow: _selectedIndex == 2
                          ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            size: 20,
                            color: _selectedIndex == 2
                                ? (_selectedClient == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray),
                        const SizedBox(width: 8),
                        Text(
                          'Clients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
                            color: _selectedIndex == 2
                                ? (_selectedClient == null ? colors.primaryBlue : colors.darkGray)
                                : colors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
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
