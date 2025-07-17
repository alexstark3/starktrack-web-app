// lib/widgets/company/company_side_menu.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

class CompanySideMenu extends StatefulWidget {
  final List<SideMenuItem> menuItems;
  final bool compact;
  final bool showBrand;

  const CompanySideMenu({
    super.key,
    required this.menuItems,
    this.compact = false,
    this.showBrand = true,
  });

  @override
  State<CompanySideMenu> createState() => _CompanySideMenuState();
}

class _CompanySideMenuState extends State<CompanySideMenu> {
  String _appInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appInfo = 'Stark Track v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final width  = widget.compact ? 72.0 : 220.0;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.80),
      clipBehavior: Clip.none,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showBrand) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  widget.compact ? 'ST' : 'Stark Track',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.30),
              ),
            ],
            // Use Expanded to push the version label to the bottom
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: widget.menuItems
                    .map((m) => _AnimatedMenuItem(item: m, compact: widget.compact))
                    .toList(),
              ),
            ),
            // Version and copyright at the bottom
            if (_appInfo.isNotEmpty && !widget.compact)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _appInfo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 starktrack.ch © All rights reserved.',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMenuItem extends StatefulWidget {
  final SideMenuItem item;
  final bool compact;
  const _AnimatedMenuItem({required this.item, required this.compact});

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHL  = widget.item.selected || _hovered;
    final color = widget.item.selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit : (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHL
                ? theme.colorScheme.primary.withOpacity(0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: color),
              if (!widget.compact) ...[
                const SizedBox(width: 12),
                Text(widget.item.label,
                    style: TextStyle(fontSize: 16, color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
