import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
import 'screens/auth/company_login_screen.dart';
import 'screens/dashboard/company_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase project ID: ${Firebase.app().options.projectId}

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    if (!tp.isReady) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    
    // Determine locale based on language setting
    Locale locale;
    switch (tp.language) {
      case 'DE':
        locale = const Locale('de');
        break;
      case 'EN':
      default:
        locale = const Locale('en');
        break;
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stark Track',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: tp.themeMode,
      locale: locale, // Set the locale based on language setting
      
      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('de'), // German
      ],
      
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) return const CompanyLoginScreen();

        final uid = snap.data!.uid;

        // Try to find the company the user belongs to by iterating all companies
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('companies').get(),
          builder: (context, companySnap) {
            if (companySnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!companySnap.hasData || companySnap.data!.docs.isEmpty) {
              return const Scaffold(body: Center(child: Text('No companies found.')));
            }

            // Search for user in each company
            return _findUserInCompanies(companySnap.data!.docs, uid);
          },
        );
      },
    );
  }

  Widget _findUserInCompanies(List<QueryDocumentSnapshot> companies, String uid) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(
        companies.map((company) => company.reference.collection('users').doc(uid).get()),
      ),
      builder: (context, usersSnap) {
        if (usersSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final docs = usersSnap.data;
        if (docs == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        for (int i = 0; i < docs.length; i++) {
          final userDoc = docs[i];
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            final companyId = companies[i].id;

            // Compose a safe full name
            final full = (data['fullName'] as String?)?.trim() ?? '';
            final first = (data['firstName'] as String?)?.trim() ?? '';
            final sur = (data['surname'] as String?)?.trim() ?? '';
            final fullName = full.isNotEmpty ? full : '$first $sur'.trim();

            // --- SAFE EXTRACTION ---
            final email = (data['email'] ?? '') as String;
            final roles = (data['roles'] is List)
                ? (data['roles'] as List).map((e) => e.toString()).toList()
                : <String>[];
            final modules = (data['modules'] is List)
        ? (data['modules'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final access = <String, dynamic>{
      'time_tracker': modules.contains('time_tracker'),
      'admin'       : modules.contains('admin'),
    };

            return CompanyDashboardScreen(
              companyId: companyId,
              userId: uid,
              fullName: fullName,
              email: email,
              roles: roles,
              access: access,
            );
          }
        }

        return const Scaffold(body: Center(child: Text('User not assigned to any company.')));
      },
    );
  }
}
