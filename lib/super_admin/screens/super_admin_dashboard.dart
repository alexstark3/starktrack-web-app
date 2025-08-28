import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../security/super_admin_auth_service.dart';
import '../../theme/app_colors.dart';
import 'super_admin_login.dart';
import '../tools/company_migration_tool.dart';
import '../security/firestore_backup_service.dart';
import 'company_management_screen.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  Map<String, dynamic>? _adminData;
  bool _isLoading = true;
  bool _forceLogout = false;
  bool _isForceLogoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _listenForceLogout();
  }

  void _listenForceLogout() {
    FirebaseFirestore.instance
        .collection('appConfig')
        .doc('global')
        .snapshots()
        .listen((doc) {
      if (mounted) {
        if (doc.exists && doc.data()?['forceLogout'] == true) {
          setState(() => _forceLogout = true);
        } else {
          setState(() => _forceLogout = false);
        }
      }
    });
  }

  Future<void> _setForceLogout(bool value) async {
    if (mounted) {
      setState(() => _isForceLogoutLoading = true);
    }
    await FirebaseFirestore.instance
        .collection('appConfig')
        .doc('global')
        .set({'forceLogout': value}, SetOptions(merge: true));
    if (mounted) {
      setState(() => _isForceLogoutLoading = false);
    }
  }

  Future<void> _loadAdminData() async {
    final adminData = await SuperAdminAuthService.getAdminData();
    if (mounted) {
      setState(() {
        _adminData = adminData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    if (colors == null) {
      return const Scaffold(
        body: Center(child: Text('Theme error: AppColors not found')),
      );
    }
    // final l10n = AppLocalizations.of(context)!; // Remove unused variable

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminData == null) {
      return Scaffold(
        backgroundColor: colors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Super Admin access denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have super admin privileges',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminLoginScreen(),
                    ),
                  );
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    final roles = List<String>.from(_adminData!['roles'] ?? []);
    final isSuperAdmin = roles.contains('super_admin');

    return Scaffold(
      backgroundColor: colors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Super Admin Dashboard',
          style: TextStyle(color: colors.textColor),
        ),
        backgroundColor: colors.cardColorDark,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colors.textColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SuperAdminLoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Info Card
              Card(
                color: colors.cardColorDark,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_adminData!['firstName']} ${_adminData!['surname']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _adminData!['email'],
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Roles: ${roles.join(', ')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Super Admin Actions
              Text(
                'Super Admin Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 16),

              // Company Management
              _buildActionCard(
                context,
                title: 'Company Management',
                subtitle: 'View and manage all companies',
                icon: Icons.business,
                color: colors.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompanyManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // User Management
              _buildActionCard(
                context,
                title: 'User Management',
                subtitle: 'Manage admin users',
                icon: Icons.people,
                color: Colors.green,
                onTap: () {
                  // Treba da se napraa Navigate to admin user management
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Admin User Management - Coming Soon')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // System Statistics
              _buildActionCard(
                context,
                title: 'System Statistics',
                subtitle: 'View system usage and metrics',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () {
                  // Treba da se napraa Navigate to system statistics
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('System Statistics - Coming Soon')),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Backup Database Button
              ElevatedButton.icon(
                icon: Icon(Icons.download, color: colors.whiteTextOnBlue),
                label: Text('Backup Database',
                    style: TextStyle(color: colors.whiteTextOnBlue)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final json =
                      await FirestoreBackupService.backupAllCompaniesAsJson();
                  final bytes = utf8.encode(json);
                  await FileSaver.instance.saveFile(
                    name: 'firestore_backup',
                    ext: 'json',
                    bytes: Uint8List.fromList(bytes),
                    mimeType: MimeType.json,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Restore from Backup Button
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file, color: colors.whiteTextOnBlue),
                label: Text('Restore from Backup',
                    style: TextStyle(color: colors.whiteTextOnBlue)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    final json = utf8.decode(file.bytes ?? []);
                    
                    if (!context.mounted) return;
                    
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Restore'),
                        content: const Text(
                            'Restoring from backup will overwrite existing data for the same IDs. Are you sure you want to continue?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await FirestoreBackupService.restoreFromJson(json);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Restore completed successfully!'),
                                backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Restore failed: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // Migration Tool (Super Admin only)
              if (isSuperAdmin) ...[
                _buildActionCard(
                  context,
                  title: 'Company Migration Tool',
                  subtitle: 'Migrate companies to secure IDs',
                  icon: Icons.security,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CompanyMigrationTool(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Force Logout Toggle
              Row(
                children: [
                  Switch(
                    value: _forceLogout,
                    onChanged: _isForceLogoutLoading
                        ? null
                        : (val) => _setForceLogout(val),
                    activeThumbColor: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _forceLogout
                          ? 'Force Logout ON (Maintenance Mode)'
                          : 'Force Logout OFF',
                      style: TextStyle(
                        color: _forceLogout ? Colors.red : colors.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isForceLogoutLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Card(
      color: colors.cardColorDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.textColor.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

