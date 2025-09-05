import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/auth/company_login_screen.dart';
import 'home.dart';
import 'contact.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Home(
      onLogoPressed: () => Navigator.pop(context),
      onHomePressed: () => Navigator.pop(context),
      onFeaturesPressed: () => Navigator.pop(context),
      onPricingPressed: () => Navigator.pop(context),
      onContactPressed: () => Navigator.pop(context),
      onLoginPressed: () {
        // Navigate to app login page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CompanyLoginScreen(),
          ),
        );
      },
      onAboutUsPressed: () {}, // Current page
      content: _buildAboutUsContent(colors, context),
    );
  }

  Widget _buildAboutUsContent(AppColors colors, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo
              Center(
                child: Image.asset(
                  'assets/images/logo_full.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 60),
          
          // Company Story Section
          _buildSection(
            l10n.ourStory,
            l10n.ourStoryContent,
            colors,
          ),
          
          const SizedBox(height: 48),
          
          // Mission Section
          _buildSection(
            l10n.ourMission,
            l10n.ourMissionContent,
            colors,
          ),
          
          const SizedBox(height: 48),
          
          // Values Section
          _buildSection(
            l10n.ourValues,
            l10n.ourValuesContent,
            colors,
          ),
          
          const SizedBox(height: 48),
          
          // Why Choose Us Section
          _buildSection(
            l10n.whyChooseStarkTrack,
            l10n.whyChooseStarkTrackContent,
            colors,
          ),
          
          const SizedBox(height: 60),
          
          // Contact Section
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.getInTouch,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.haveQuestionsAboutStarkTrack,
                    style: TextStyle(
                      fontSize: 18,
                      color: colors.textColor.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryBlue,
                      foregroundColor: colors.whiteTextOnBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          content,
          style: TextStyle(
            fontSize: 18,
            color: colors.textColor.withValues(alpha: 0.8),
            height: 1.7,
          ),
        ),
      ],
    );
  }
}