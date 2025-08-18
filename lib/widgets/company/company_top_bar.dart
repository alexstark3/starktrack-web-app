import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class CompanyTopBar extends StatefulWidget {
  static const double kHeight = 56;

  final String screenTitle;
  final String fullName;
  final String email;
  final String initials;
  final String selectedScreen;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const CompanyTopBar({
    super.key,
    required this.screenTitle,
    required this.fullName,
    required this.email,
    required this.initials,
    required this.selectedScreen,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  State<CompanyTopBar> createState() => _CompanyTopBarState();
}

class _CompanyTopBarState extends State<CompanyTopBar> {
  bool _isHovered = false;

  void _showMenu(BuildContext context) {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 110, // Center the menu (button is 36px, menu is ~220px, so offset by (220-36)/2 = 92, but adjust for better centering)
        offset.dy + button.size.height, // Top position (below the button)
        offset.dx + button.size.width, // Right position
        offset.dy, // Bottom position
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          value: 'info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  )),
              const SizedBox(height: 2),
              Text(widget.email, style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              )),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'settings',
          onTap: widget.onSettings,
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.settings,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          onTap: widget.onLogout,
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.logout,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(                       // separate layer ⇒ guaranteed shadow
      elevation: 6,                        // ← try 3-4 dp: clearly visible
      color: theme.colorScheme.surface, // bar colour
      shadowColor:
          Colors.black.withValues(alpha:0.4),  // subtle but visible on white
      child: SizedBox(
        height: CompanyTopBar.kHeight,
        child: Row(
          children: [
            /* ─ screen title ─ */
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.screenTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            /* ─ square avatar & popup ─ */
            Padding(
              padding: const EdgeInsets.only(right: 12),
                                                             child: Builder(
                 builder: (buttonContext) => GestureDetector(
                   onTap: () => _showMenu(buttonContext),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isHovered 
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)  // Slightly darker on hover
                          : theme.colorScheme.primary,   // Normal blue
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isHovered ? 0.3 : 0.15),
                          offset: Offset(0, _isHovered ? 3 : 1),
                          blurRadius: _isHovered ? 6 : 3,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
               ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
