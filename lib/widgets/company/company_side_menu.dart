import 'package:flutter/material.dart';

class SideMenuItem {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  SideMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
}

class CompanySideMenu extends StatelessWidget {
  final List<SideMenuItem> menuItems;

  const CompanySideMenu({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      color: theme.colorScheme.background, // ⬅️ themed background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: menuItems.map((item) => _AnimatedMenuItem(item: item)).toList(),
      ),
    );
  }
}

class _AnimatedMenuItem extends StatefulWidget {
  final SideMenuItem item;

  const _AnimatedMenuItem({required this.item});

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.item.selected;
    final showHighlight = isSelected || _hovered;

    final highlightColor = theme.colorScheme.primary.withOpacity(0.2);
    final iconTextColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: showHighlight ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: iconTextColor),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(fontSize: 16, color: iconTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
