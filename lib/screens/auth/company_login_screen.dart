import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/company/login_form.dart'; // Adjust if needed
import '../dashboard/company_dashboard_screen.dart'; // Adjust if needed

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({Key? key}) : super(key: key);

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Sign in with Firebase Auth
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final userId = authResult.user!.uid;
      print('LOGIN: Authenticated with UID=$userId');

      // 2. Find the company the user belongs to (no hardcoding)
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      String? companyId;
      DocumentSnapshot<Map<String, dynamic>>? userDocSnap;

      for (var companyDoc in companiesSnapshot.docs) {
        final potentialUserDoc = await companyDoc.reference
            .collection('users')
            .doc(userId)
            .get();
        if (potentialUserDoc.exists) {
          companyId = companyDoc.id;
          userDocSnap = potentialUserDoc;
          break;
        }
      }

      if (companyId == null || userDocSnap == null) {
        print('LOGIN: No company assigned for this user.');
        setState(() {
          _error = 'You are not assigned to any company. Contact your administrator.';
        });
        return;
      }

      final data = userDocSnap.data()!;
      // --- SAFE EXTRACTION ---
      final roles = (data['roles'] is List)
          ? (data['roles'] as List).map((e) => e.toString()).toList()
          : <String>[];
      final access = (data['access'] is Map)
          ? Map<String, dynamic>.from(data['access'] as Map)
          : <String, dynamic>{};
      final email = (data['email'] ?? '') as String;
      final firstName = (data['firstName'] ?? '') as String;
      final surname = (data['surname'] ?? '') as String;
      final fullName = (firstName + ' ' + surname).trim();

      print('LOGIN: User found! Navigating to dashboard for company $companyId');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompanyDashboardScreen(
            companyId: companyId!,
            userId: userId,
            roles: roles,
            access: access,
            fullName: fullName,
            email: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print('LOGIN: FirebaseAuthException: ${e.message}');
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      print('LOGIN: Unknown error: $e');
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
