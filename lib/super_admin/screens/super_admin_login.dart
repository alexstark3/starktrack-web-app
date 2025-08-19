import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../security/super_admin_auth_service.dart';
import '../services/admin_version_service.dart';
import '../../theme/app_colors.dart';
import 'super_admin_dashboard.dart';
import 'package:web/web.dart' as web;
import '../../utils/browser_persistence.dart';
import '../../utils/app_logger.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadVersion();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final savedEmail = await BrowserPersistence.loadSuperAdminEmail();

      if (mounted && savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    } catch (e) {
      AppLogger.error('Error loading saved super admin login data: $e');
    }
  }

  Future<void> _saveLoginData() async {
    try {
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        await BrowserPersistence.saveSuperAdminEmail(email, true);
      }
    } catch (e) {
      AppLogger.error('Error saving super admin login data: $e');
    }
  }

  Future<void> _loadVersion() async {
    try {
      // Use the admin version service
      final adminVersion = await AdminVersionService.getAdminVersion();
      setState(() {
        _version = adminVersion;
      });
    } catch (e) {
      AppLogger.error('Error loading admin version: $e');
      setState(() {
        _version = '1.1.1.0'; // Fallback version
      });
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final isAdmin = await SuperAdminAuthService.isAdmin();
          
          if (isAdmin) {
            // Save login data before navigation
            await _saveLoginData();
            
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const SuperAdminDashboardScreen(),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'Access denied. You do not have super admin privileges.';
              _isLoading = false;
            });
            await FirebaseAuth.instance.signOut();
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Sign in failed: ${e.toString()}';
          _isLoading = false;
        });
      }
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

    return Scaffold(
      backgroundColor: colors.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: colors.cardColorDark,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Admin Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 48,
                          color: colors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Title
                      Text(
                        'Stark Track',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        'Super Admin Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email address',
                          prefixIcon:
                              Icon(Icons.email, color: colors.primaryBlue),
                          filled: true,
                          fillColor: colors.lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: colors.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon:
                              Icon(Icons.lock, color: colors.primaryBlue),
                          filled: true,
                          fillColor: colors.lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: colors.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => !_isLoading ? _signIn() : null,
                      ),
                      const SizedBox(height: 8),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: colors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryBlue,
                            foregroundColor: colors.whiteTextOnBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to Main App
                      TextButton(
                        onPressed: () {
                          web.window.location.href = 'https://starktrack.ch';
                        },
                        child: Text(
                          'Back to Main App',
                          style: TextStyle(
                            color: colors.primaryBlue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Version Display
                      if (_version.isNotEmpty)
                        Text(
                          'Version: $_version',
                          style: TextStyle(
                            color: colors.textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  // Replace deprecated onWillPop by handling back pop intent
                  onPopInvokedWithResult: (didPop, result) async {
                    if (!didPop && !_isLoading) {
                      await _signIn();
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
