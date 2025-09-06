import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'top_menu.dart';
import 'futter.dart';

class Home extends StatelessWidget {
  final Widget content;
  final ScrollController? scrollController;
  final VoidCallback? onLogoPressed;
  final VoidCallback? onHomePressed;
  final VoidCallback? onFeaturesPressed;
  final VoidCallback? onPricingPressed;
  final VoidCallback? onContactPressed;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onAboutUsPressed;
  final String? buttonText;

  const Home({
    super.key,
    required this.content,
    this.scrollController,
    this.onLogoPressed,
    this.onHomePressed,
    this.onFeaturesPressed,
    this.onPricingPressed,
    this.onContactPressed,
    this.onLoginPressed,
    this.onAboutUsPressed,
    this.buttonText = 'Login',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            // Top Navigation Bar
            TopMenu(
              onLogoPressed: onLogoPressed,
              onHomePressed: onHomePressed,
              onFeaturesPressed: onFeaturesPressed,
              onPricingPressed: onPricingPressed,
              onContactPressed: onContactPressed,
              onAboutUsPressed: onAboutUsPressed,
              onLoginPressed: onLoginPressed,
              buttonText: buttonText,
            ),
            
            // Main Content with responsive padding and max width
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 20,
                    vertical: isMobile ? 20 : 40,
                  ),
                  child: content,
                ),
              ),
            ),
            
            // Footer
            Footer(
              onHomePressed: onHomePressed,
              onFeaturesPressed: onFeaturesPressed,
              onPricingPressed: onPricingPressed,
              onContactPressed: onContactPressed,
              onAboutUsPressed: onAboutUsPressed,
            ),
          ],
        ),
      ),
    );
  }
}
