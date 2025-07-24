import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../security/super_admin_auth_service.dart';
import '../../theme/app_colors.dart';
import 'super_admin_dashboard.dart';
import 'package:web/web.dart' as web;
import '../../utils/browser_persistence.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
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
      print('Error loading saved super admin login data: $e');
    }
  }

  Future<void> _saveLoginData() async {
    try {
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        await BrowserPersistence.saveSuperAdminEmail(email, true);
      }
    } catch (e) {
      print('Error saving super admin login data: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if user is an admin
      final isAdmin = await SuperAdminAuthService.isAdmin();
      
      if (!isAdmin) {
        // Sign out if not admin
        await FirebaseAuth.instance.signOut();
              if (mounted) {
        setState(() {
          _errorMessage = 'Access denied. Super admin privileges required.';
          _isLoading = false;
        });
      }
        return;
      }

      // Save email for browser persistence (if remember me is enabled)
      await _saveLoginData();
      if (!mounted) return;

      // Navigate to admin dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SuperAdminDashboardScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No super admin account found with this email.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMsg = 'Login failed. Please try again.';
      }
      
      if (mounted) {
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
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
                          color: colors.primaryBlue.withOpacity(0.1),
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
                          prefixIcon: Icon(Icons.email, color: colors.primaryBlue),
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
                            borderSide: BorderSide(color: colors.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                          prefixIcon: Icon(Icons.lock, color: colors.primaryBlue),
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
                            borderSide: BorderSide(color: colors.primaryBlue, width: 2),
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
                        onFieldSubmitted: (_) => !_isLoading ? _login() : null,
                      ),
                      const SizedBox(height: 8),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.error.withOpacity(0.1),
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
                          onPressed: _isLoading ? null : _login,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    ],
                  ),
                  // Add this to allow form submit on Enter
                  onWillPop: () async {
                    if (!_isLoading) await _login();
                    return false;
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