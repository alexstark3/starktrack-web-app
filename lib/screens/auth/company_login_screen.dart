import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/company/login_form.dart';
import '../dashboard/company_dashboard_screen.dart';
import '../../super_admin/security/login_rate_limiter.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/browser_persistence.dart';
import '../../utils/app_logger.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  String? _error;

  /// Save email for browser persistence
  Future<void> _saveEmailForPersistence(String email) async {
    try {
      if (email.isNotEmpty) {
        await BrowserPersistence.saveUserEmail(email, true);
      }
    } catch (e) {
      AppLogger.warn('Error saving email for persistence',
          name: 'CompanyLogin', error: e);
    }
  }

  Future<void> _login() async {
    if (!mounted) return;

    final userEmail = _emailController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Check if user can attempt login (rate limiting)
      final canAttempt = await LoginRateLimiter.canAttemptLogin(userEmail);
      if (!mounted) return;
      if (!canAttempt) {
        final lockoutTime =
            await LoginRateLimiter.getRemainingLockoutTime(userEmail);
        if (!mounted) return;
        if (lockoutTime != null) {
          final minutes = lockoutTime.inMinutes + 1; // Round up
          setState(() {
            _error = l10n.accountLockedMessage(minutes);
          });
          return;
        }
      }

      // 2. Sign in with Firebase Auth
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final userId = authResult.user!.uid;
      // AppLogger.debug('Authenticated with UID=$userId', name: 'CompanyLogin');

      // 2. Find the company the user belongs to using userCompany collection
      final userCompanyDoc = await FirebaseFirestore.instance
          .collection('userCompany')
          .doc(userId)
          .get();
      if (!mounted) return;

      if (!userCompanyDoc.exists) {
        setState(() {
          _error =
              'You are not assigned to any company. Contact your administrator.';
        });
        return;
      }

      final companyId = userCompanyDoc['companyId'] as String;

      // 3. Get user data from the company users subcollection
      final userDocSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(userId)
          .get();
      if (!mounted) return;

      if (!userDocSnap.exists) {
        setState(() {
          _error =
              'User data not found in company. Contact your administrator.';
        });
        return;
      }

      final data = userDocSnap.data()!;
      // --- SAFE EXTRACTION ---
      final roles = (data['roles'] is List)
          ? (data['roles'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final modules = (data['modules'] is List)
          ? (data['modules'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final access = <String, dynamic>{
        'time_tracker': modules.contains('time_tracker'),
        'admin': modules.contains('admin'),
      };

      final String email = (data['email'] ?? '') as String;
      final String firstName = (data['firstName'] ?? '') as String;
      final String surname = (data['surname'] ?? '') as String;
      final String fullName = '${firstName.trim()} ${surname.trim()}'.trim();

      // 4. Record successful login (reset rate limiting)
      await LoginRateLimiter.recordSuccessfulLogin(email);
      if (!mounted) return;

      // 5. Save email for browser persistence
      await _saveEmailForPersistence(userEmail);
      if (!mounted) return;

      // Only navigate once!
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompanyDashboardScreen(
            companyId: companyId,
            userId: userId,
            roles: roles,
            access: access,
            fullName: fullName,
            email: email,
          ),
        ),
      );
      // AppLogger.info('Navigating to dashboard for company $companyId', name: 'CompanyLogin');
    } on FirebaseAuthException catch (e) {
      AppLogger.warn('FirebaseAuthException',
          name: 'CompanyLogin', error: e, stackTrace: e.stackTrace);
      if (!mounted) return;

      // Record failed login attempt for rate limiting
      await LoginRateLimiter.recordFailedAttempt(userEmail);
      if (!mounted) return;

      // Get remaining attempts for user feedback
      final remainingAttempts =
          await LoginRateLimiter.getRemainingAttempts(userEmail);
      if (!mounted) return;

      setState(() {
        if (remainingAttempts <= 0) {
          // Account is now locked
          _error = l10n.tooManyFailedAttempts;
        } else {
          // Show remaining attempts
          _error =
              '${e.message ?? 'Authentication failed'}\n${l10n.remainingAttempts(remainingAttempts)}';
        }
      });
    } catch (e) {
      AppLogger.error('Unknown error during login',
          name: 'CompanyLogin', error: e);
      if (!mounted) return;

      // Record failed login attempt for rate limiting
      await LoginRateLimiter.recordFailedAttempt(userEmail);
      if (!mounted) return;

      setState(() {
        _error = 'Unknown error: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginForm(
        emailController: _emailController,
        passwordController: _passwordController,
        passwordFocus: _passwordFocus,
        loading: _isLoading,
        error: _error,
        onLogin: _login,
      ),
    );
  }
}
