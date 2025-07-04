import 'package:flutter/material.dart';

class UserProfileMenu extends StatefulWidget {
  final String initials;
  final String fullName;
  final String email;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const UserProfileMenu({
    super.key,
    required this.initials,
    required this.fullName,
    required this.email,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  bool _showMenu = false;

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1490DE).withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_showMenu)
          Positioned(
            top: 48,
            right: 0,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Settings'),
                      onTap: widget.onSettings,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Log out'),
                      onTap: widget.onLogout,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
