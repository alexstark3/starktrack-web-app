import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class Footer extends StatelessWidget {
  final VoidCallback? onHomePressed;
  final VoidCallback? onFeaturesPressed;
  final VoidCallback? onPricingPressed;
  final VoidCallback? onContactPressed;
  final VoidCallback? onAboutUsPressed;

  const Footer({
    super.key,
    this.onHomePressed,
    this.onFeaturesPressed,
    this.onPricingPressed,
    this.onContactPressed,
    this.onAboutUsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: isMobile ? 24 : 40,
      ),
      color: colors.textColor,
      child: Column(
        children: [
          isMobile ? _buildMobileLayout(l10n, colors) : _buildDesktopLayout(l10n, colors),
          SizedBox(height: isMobile ? 24 : 40),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2024 Stark Track. ${l10n.allRightsReserved}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo and description
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo_full.png',
              height: 32,
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.professionalTimeTrackingForTeams,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Footer Links - wrapped under description
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildFooterLink(l10n.home, colors, onHomePressed),
            _buildFooterLink(l10n.features, colors, onFeaturesPressed),
            _buildFooterLink(l10n.pricing, colors, onPricingPressed),
            _buildFooterLink(l10n.contact, colors, onContactPressed),
            _buildFooterLink(l10n.aboutUs, colors, onAboutUsPressed),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppLocalizations l10n, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo and description
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo_full.png',
              height: 32,
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.professionalTimeTrackingForTeams,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        // Footer Links
        Row(
          children: [
            _buildFooterLink(l10n.home, colors, onHomePressed),
            const SizedBox(width: 32),
            _buildFooterLink(l10n.features, colors, onFeaturesPressed),
            const SizedBox(width: 32),
            _buildFooterLink(l10n.pricing, colors, onPricingPressed),
            const SizedBox(width: 32),
            _buildFooterLink(l10n.contact, colors, onContactPressed),
            const SizedBox(width: 32),
            _buildFooterLink(l10n.aboutUs, colors, onAboutUsPressed),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, AppColors colors, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
    );
  }
}
