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
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // PackageInfo loaded - version: "${packageInfo.version}", buildNumber: "${packageInfo.buildNumber}"
      // Platform: ${kIsWeb ? 'Web' : 'Native'}

      // Create clean version format: 1.1.641 instead of 1.1.1+641
      String cleanVersion = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      // If version contains + (like 1.1.1+641), extract the base version and build number
      if (cleanVersion.contains('+')) {
        List<String> parts = cleanVersion.split('+');
        String baseVersion = parts[0]; // 1.1.1
        String buildNum = parts.length > 1 ? parts[1] : buildNumber; // 641

        // Create clean format: replace last part of base version with build number
        List<String> versionParts = baseVersion.split('.');
        if (versionParts.length >= 3) {
          versionParts[2] = buildNum; // Replace 1 with 641
          cleanVersion = versionParts.join('.'); // 1.1.641
        }
      } else {
        // If version doesn't contain +, combine version and build number manually
        List<String> versionParts = cleanVersion.split('.');
        if (versionParts.length >= 3 && buildNumber.isNotEmpty) {
          versionParts[2] = buildNumber; // Replace last part with build number
          cleanVersion = versionParts.join('.'); // 1.1.641
        }
      }

      setState(() {
        _appInfo = 'Stark Track $cleanVersion';
      });
      // Final app info: $_appInfo
    } catch (e) {
      // Error loading app info: $e
      setState(() {
        _appInfo = 'Stark Track 1.1.633'; // Fallback with clean version format
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.compact
        ? 56.0
        : 220.0; // Increased from 40.0 to 56.0 to match dashboard

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.80),
      clipBehavior: Clip.none,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showBrand) ...[
              const SizedBox(height: 12), // Restore original
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        widget.compact ? 16 : 25), // Keep horizontal reduction
                child: Text(
                  widget.compact ? 'ST' : 'Stark Track',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18), // Restore original
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
              ),
            ],
            // Use Expanded to push the version label to the bottom
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: widget.menuItems
                    .map((m) =>
                        _AnimatedMenuItem(item: m, compact: widget.compact))
                    .toList(),
              ),
            ),
            // Version and copyright at the bottom
            if (_appInfo.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 8 : 16,
                    vertical: 8), // Reduced from 16 to 8 in compact mode
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                _appInfo.replaceAll('Stark Track ', ''),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _appInfo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 4),
                      Text(
                        '© 2025 starktrack.ch\n© All rights reserved.',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
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
    final isHL = widget.item.selected || _hovered;
    final color = widget.item.selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(
              horizontal: widget.compact ? 2 : 12,
              vertical:
                  6), // Reduced horizontal margin from 4 to 2 in compact mode
          padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 2 : 12,
              vertical:
                  10), // Reduced horizontal padding from 4 to 2 in compact mode
          decoration: BoxDecoration(
            color: isHL
                ? theme.colorScheme.primary.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.compact
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(widget.item.icon, color: color, size: 26),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(widget.item.icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.item.label,
                          style: TextStyle(fontSize: 16, color: color)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
