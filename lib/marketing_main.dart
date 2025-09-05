import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'marketing/landing_page.dart';
import 'marketing/contact.dart';
import 'marketing/about_us.dart';
import 'providers/theme_provider.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
//flutter run -d chrome --target lib/marketing_main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const StarkTrackMarketingApp());
}

class StarkTrackMarketingApp extends StatelessWidget {
  const StarkTrackMarketingApp({super.key});

  Locale _getLocaleFromLanguage(String language) {
    switch (language) {
      case 'DE':
        return const Locale('de', '');
      case 'FR':
        return const Locale('fr', '');
      case 'IT':
        return const Locale('it', '');
      case 'EN':
      default:
        return const Locale('en', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Stark Track - Professional Time Tracking',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            locale: _getLocaleFromLanguage(themeProvider.language),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('de', ''),
              Locale('fr', ''),
              Locale('it', ''),
            ],
            routes: {
              '/': (context) => const MarketingHomePage(),
              '/contact': (context) => const ContactPage(),
              '/about': (context) => const AboutUsPage(),
            },
          );
        },
      ),
    );
  }
}

class MarketingHomePage extends StatelessWidget {
  const MarketingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingPage();
  }
}
