import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/auth/company_login_screen.dart';
import 'about_us.dart';
import 'contact.dart';
import 'home.dart';
import 'carousel.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero).dy;
    final scrollPosition = _scrollController.offset + position - 100; // 100px offset for better visibility
    
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutUsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Home(
      scrollController: _scrollController,
      onLogoPressed: () {
        // Logo click - scroll to top
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      },
      onHomePressed: () {
        // Home click - scroll to top
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      },
      onFeaturesPressed: () => _scrollToSection(_featuresKey),
      onPricingPressed: () => _scrollToSection(_pricingKey),
      onContactPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContactPage(),
          ),
        );
      },
      onLoginPressed: () {
        // Navigate to app login page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CompanyLoginScreen(),
          ),
        );
      },
      onAboutUsPressed: () => _navigateToAboutUs(),
      content: Column(
        children: [
          // Hero Section
          _buildHeroSection(colors),
          
          // Features Section
          _buildFeaturesSection(colors, _featuresKey),
          
          // How It Works Section
          _buildHowItWorksSection(colors),
          
          // Pricing Section
          _buildPricingSection(colors, _pricingKey),
          
          // Call to Action Section
          _buildCallToActionSection(colors, _contactKey),
        ],
      ),
    );
  }



  Widget _buildHeroSection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Main Headline
          Text(
            AppLocalizations.of(context)!.timeTrackingMadeSimple,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Subtitle
          SizedBox(
            width: 600,
            child: Text(
              AppLocalizations.of(context)!.professionalTimeTracking,
              style: TextStyle(
                fontSize: 20,
                color: colors.textColor.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          // CTA Buttons - Responsive
          _buildCTAButtons(colors),
          const SizedBox(height: 60),
          
          // Hero Dashboard Carousel
          const DashboardCarousel(),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(AppColors colors) {
    // Single "Start Free Trial" button for all screen sizes
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactPage(interestedIn: 'Free Trial'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.startFreeTrial,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(AppColors colors, GlobalKey key) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 10, 
        vertical: isMobile ? 10 : 10
      ),
      child: Column(
        children: [
          // Section Title
          Text(
            AppLocalizations.of(context)!.everythingYouNeedToTrackTime,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.powerfulFeaturesDesigned,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 40 : 60),
          
          // Features Grid - Responsive
          isMobile ? _buildMobileFeaturesGrid(colors) : _buildDesktopFeaturesGrid(colors),
          SizedBox(height: isMobile ? 40 : 60),
          
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 30,
              color: colors.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: colors.textColor.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeaturesGrid(AppColors colors) {
    return Column(
      children: [
        _buildFeatureCard(
          Icons.timer,
          AppLocalizations.of(context)!.timeTracking,
          AppLocalizations.of(context)!.trackTimeWithPrecision,
          colors,
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          Icons.people,
          AppLocalizations.of(context)!.teamManagement,
          AppLocalizations.of(context)!.manageYourTeam,
          colors,
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          Icons.analytics,
          AppLocalizations.of(context)!.reportsAnalytics,
          AppLocalizations.of(context)!.generateDetailedReports,
          colors,
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          Icons.work,
          AppLocalizations.of(context)!.projectManagement,
          AppLocalizations.of(context)!.organizeAndTrack,
          colors,
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          Icons.mobile_friendly,
          AppLocalizations.of(context)!.mobileResponsive,
          AppLocalizations.of(context)!.accessFromAnywhere,
          colors,
        ),
        const SizedBox(height: 20),
        _buildFeatureCard(
          Icons.security,
          AppLocalizations.of(context)!.secureReliable,
          AppLocalizations.of(context)!.dataSafeWithEnterprise,
          colors,
        ),
      ],
    );
  }

  Widget _buildDesktopFeaturesGrid(AppColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                Icons.timer,
                AppLocalizations.of(context)!.timeTracking,
                AppLocalizations.of(context)!.trackTimeWithPrecision,
                colors,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                Icons.people,
                AppLocalizations.of(context)!.teamManagement,
                AppLocalizations.of(context)!.manageYourTeam,
                colors,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                Icons.analytics,
                AppLocalizations.of(context)!.reportsAnalytics,
                AppLocalizations.of(context)!.generateDetailedReports,
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                Icons.work,
                AppLocalizations.of(context)!.projectManagement,
                AppLocalizations.of(context)!.organizeAndTrack,
                colors,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                Icons.mobile_friendly,
                AppLocalizations.of(context)!.mobileResponsive,
                AppLocalizations.of(context)!.accessFromAnywhere,
                colors,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                Icons.security,
                AppLocalizations.of(context)!.secureReliable,
                AppLocalizations.of(context)!.dataSafeWithEnterprise,
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection(AppColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20, 
        vertical: isMobile ? 40 : 80
      ),
      color: colors.primaryBlue.withValues(alpha: 0.05),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.howItWorks,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 40 : 60),
          
          // Steps - Responsive
          isMobile ? _buildMobileSteps(colors) : _buildDesktopSteps(colors),
        ],
      ),
    );
  }

  Widget _buildMobileSteps(AppColors colors) {
    return Column(
      children: [
        _buildStepCard(
          '1',
          AppLocalizations.of(context)!.signUp,
          AppLocalizations.of(context)!.createAccountAndSetup,
          colors,
        ),
        const SizedBox(height: 40),
        _buildStepCard(
          '2',
          AppLocalizations.of(context)!.startTracking,
          AppLocalizations.of(context)!.beginTrackingTime,
          colors,
        ),
        const SizedBox(height: 40),
        _buildStepCard(
          '3',
          AppLocalizations.of(context)!.analyzeAndImprove,
          AppLocalizations.of(context)!.reviewReportsAndOptimize,
          colors,
        ),
      ],
    );
  }

  Widget _buildDesktopSteps(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildStepCard(
            '1',
            AppLocalizations.of(context)!.signUp,
            AppLocalizations.of(context)!.createAccountAndSetup,
            colors,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStepCard(
            '2',
            AppLocalizations.of(context)!.startTracking,
            AppLocalizations.of(context)!.beginTrackingTime,
            colors,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStepCard(
            '3',
            AppLocalizations.of(context)!.analyzeAndImprove,
            AppLocalizations.of(context)!.reviewReportsAndOptimize,
            colors,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String step, String title, String description, AppColors colors) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors.primaryBlue,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textColor.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: colors.textColor.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingSection(AppColors colors, GlobalKey key) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.simpleTransparentPricing,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.choosePlanThatFits,
            style: TextStyle(
              fontSize: 18,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          // Pricing Cards - Progressive Responsive Layout
          _buildResponsivePricingCards(colors, screenWidth),
        ],
      ),
    );
  }

  Widget _buildResponsivePricingCards(AppColors colors, double screenWidth) {
    // Calculate available width (screen width - container padding)
    final availableWidth = screenWidth - 48; // 24px padding on each side
    
    
    // Wrap sooner to prevent overflow
    if (availableWidth >= 1370) { // Wrap at 1300px 4x1 layout - all cards in a row
      return _buildDesktopPricingCards(colors);
    } else if (availableWidth >= 700) {
      // 2x2 layout - cards in 2 rows of 2
      return _build2x2PricingCards(colors);
    } else {
      // 1x4 layout - all cards stacked vertically
      return _buildMobilePricingCards(colors);
    }
  }

  Widget _build2x2PricingCards(AppColors colors) {
    return Column(
      children: [
        // First row: Demo Trial + Starter
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPricingCard(
              AppLocalizations.of(context)!.demoTrial,
              AppLocalizations.of(context)!.free,
              AppLocalizations.of(context)!.tryBeforeYouBuy,
              [
                AppLocalizations.of(context)!.fourteenDayFreeTrial,
                AppLocalizations.of(context)!.fullAccessToAllFeatures,
                AppLocalizations.of(context)!.upToFiveUsers,
                AppLocalizations.of(context)!.emailSupport,
                AppLocalizations.of(context)!.noCreditCardRequired,
              ],
              colors,
              isPopular: false,
            ),
            const SizedBox(width: 24),
            _buildPricingCard(
              AppLocalizations.of(context)!.starter,
              AppLocalizations.of(context)!.starterPrice,
              AppLocalizations.of(context)!.bestForSmallTeams,
              [
                AppLocalizations.of(context)!.upToFiveUsers,
                AppLocalizations.of(context)!.basicTimeTracking,
                AppLocalizations.of(context)!.mobileWebAccess,
                AppLocalizations.of(context)!.emailSupport,
              ],
              colors,
              isPopular: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Second row: Professional + Enterprise
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPricingCard(
              AppLocalizations.of(context)!.professional,
              AppLocalizations.of(context)!.professionalPrice,
              AppLocalizations.of(context)!.bestForMediumTeams,
              [
                AppLocalizations.of(context)!.unlimitedProjects,
                AppLocalizations.of(context)!.advancedReporting,
                AppLocalizations.of(context)!.teamManagement,
                AppLocalizations.of(context)!.timeOffManagement,
                AppLocalizations.of(context)!.prioritySupport,
                AppLocalizations.of(context)!.integrations,
              ],
              colors,
              isPopular: true,
            ),
            const SizedBox(width: 24),
            _buildPricingCard(
              AppLocalizations.of(context)!.enterprise,
              AppLocalizations.of(context)!.custom,
              AppLocalizations.of(context)!.forLargeOrganizations,
              [
                AppLocalizations.of(context)!.everythingInProfessional,
                AppLocalizations.of(context)!.customIntegrations,
                AppLocalizations.of(context)!.customReporting,
                AppLocalizations.of(context)!.dedicatedSupport,
              ],
              colors,
              isPopular: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobilePricingCards(AppColors colors) {
    return Column(
      children: [
        _buildPricingCard(
          AppLocalizations.of(context)!.demoTrial,
          'Free',
          AppLocalizations.of(context)!.tryBeforeYouBuy,
          [
            AppLocalizations.of(context)!.fourteenDayFreeTrial,
            AppLocalizations.of(context)!.fullAccessToAllFeatures,
            AppLocalizations.of(context)!.upToFiveUsers,
            AppLocalizations.of(context)!.emailSupport,
            AppLocalizations.of(context)!.noCreditCardRequired,
          ],
          colors,
          isPopular: false,
        ),
        const SizedBox(height: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.starter,
          AppLocalizations.of(context)!.starterPrice,
          AppLocalizations.of(context)!.bestForSmallTeams,
          [
            AppLocalizations.of(context)!.upToFiveUsers,
            AppLocalizations.of(context)!.basicTimeTracking,
            AppLocalizations.of(context)!.mobileWebAccess,
            AppLocalizations.of(context)!.emailSupport,
          ],
          colors,
          isPopular: false,
        ),
        const SizedBox(height: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.professional,
          AppLocalizations.of(context)!.professionalPrice,
          AppLocalizations.of(context)!.bestForMediumTeams,
          [
            AppLocalizations.of(context)!.unlimitedProjects,
            AppLocalizations.of(context)!.advancedReporting,
            AppLocalizations.of(context)!.teamManagement,
            AppLocalizations.of(context)!.timeOffManagement,
            AppLocalizations.of(context)!.prioritySupport,
            AppLocalizations.of(context)!.integrations,
          ],
          colors,
          isPopular: true,
        ),
        const SizedBox(height: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.enterprise,
          'Custom',
          AppLocalizations.of(context)!.forLargeOrganizations,
          [
            AppLocalizations.of(context)!.everythingInProfessional,
            AppLocalizations.of(context)!.customIntegrations,
            AppLocalizations.of(context)!.customReporting,
            AppLocalizations.of(context)!.dedicatedSupport,
          ],
          colors,
          isPopular: false,
        ),
      ],
    );
  }

  Widget _buildDesktopPricingCards(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPricingCard(
          AppLocalizations.of(context)!.demoTrial,
          'Free',
          AppLocalizations.of(context)!.tryBeforeYouBuy,
          [
            AppLocalizations.of(context)!.fourteenDayFreeTrial,
            AppLocalizations.of(context)!.fullAccessToAllFeatures,
            AppLocalizations.of(context)!.upToFiveUsers,
            AppLocalizations.of(context)!.emailSupport,
            AppLocalizations.of(context)!.noCreditCardRequired,
          ],
          colors,
          isPopular: false,
        ),
        const SizedBox(width: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.starter,
          AppLocalizations.of(context)!.starterPrice,
          AppLocalizations.of(context)!.bestForSmallTeams,
          [
            AppLocalizations.of(context)!.upToFiveUsers,
            AppLocalizations.of(context)!.basicTimeTracking,
            AppLocalizations.of(context)!.mobileWebAccess,
            AppLocalizations.of(context)!.emailSupport,
          ],
          colors,
          isPopular: false,
        ),
        const SizedBox(width: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.professional,
          AppLocalizations.of(context)!.professionalPrice,
          AppLocalizations.of(context)!.bestForMediumTeams,
          [
            AppLocalizations.of(context)!.unlimitedProjects,
            AppLocalizations.of(context)!.advancedReporting,
            AppLocalizations.of(context)!.teamManagement,
            AppLocalizations.of(context)!.timeOffManagement,
            AppLocalizations.of(context)!.prioritySupport,
            AppLocalizations.of(context)!.integrations,
          ],
          colors,
          isPopular: true,
        ),
        const SizedBox(width: 24),
        _buildPricingCard(
          AppLocalizations.of(context)!.enterprise,
          'Custom',
          AppLocalizations.of(context)!.forLargeOrganizations,
          [
            AppLocalizations.of(context)!.everythingInProfessional,
            AppLocalizations.of(context)!.customIntegrations,
            AppLocalizations.of(context)!.customReporting,
            AppLocalizations.of(context)!.dedicatedSupport,
          ],
          colors,
          isPopular: false,
        ),
      ],
    );
  }

  Widget _buildPricingCard(String plan, String price, String description, List<String> features, AppColors colors, {required bool isPopular}) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 320,
      ),
      width: 300,
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? colors.primaryBlue : colors.primaryBlue.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.mostPopular,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
          
          Text(
            plan,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Text(
                plan == AppLocalizations.of(context)!.starter || plan == AppLocalizations.of(context)!.professional
                    ? '${price.split('/')[0]}/${AppLocalizations.of(context)!.user}'
                    : price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              if (plan == AppLocalizations.of(context)!.starter || plan == AppLocalizations.of(context)!.professional)
                Text(
                  AppLocalizations.of(context)!.monthly,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: colors.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: colors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
                          child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactPage(interestedIn: plan),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? colors.primaryBlue : Colors.white,
                  foregroundColor: isPopular ? Colors.white : colors.primaryBlue,
                  side: BorderSide(color: colors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              child: Text(
                AppLocalizations.of(context)!.getStarted,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToActionSection(AppColors colors, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      color: colors.primaryBlue,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.readyToGetStarted,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 600,
            child: Text(
              AppLocalizations.of(context)!.joinOtherTeams,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactPage(interestedIn: 'Free Trial'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.startYourFreeTrial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
