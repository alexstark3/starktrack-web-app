import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';

class TopMenu extends StatelessWidget {
  final VoidCallback? onLogoPressed;
  final VoidCallback? onHomePressed;
  final VoidCallback? onFeaturesPressed;
  final VoidCallback? onPricingPressed;
  final VoidCallback? onContactPressed;
  final VoidCallback? onAboutUsPressed;
  final VoidCallback? onLoginPressed;
  final String? buttonText;

  const TopMenu({
    super.key,
    this.onLogoPressed,
    this.onHomePressed,
    this.onFeaturesPressed,
    this.onPricingPressed,
    this.onContactPressed,
    this.onAboutUsPressed,
    this.onLoginPressed,
    this.buttonText = 'Login',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: isMobile ? 12 : 16
      ),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile ? _buildMobileMenu(context, colors, l10n) : _buildDesktopMenu(context, colors, l10n),
    );
  }

  Widget _buildMobileMenu(BuildContext context, AppColors colors, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Logo + Hamburger + Home icon
        Row(
          children: [
            // Logo (no link)
            Image.asset(
              'assets/images/logo_collapsed.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            
            // Hamburger Menu
            PopupMenuButton<String>(
              offset: const Offset(0, 30),
              icon: Icon(
                Icons.menu,
                color: colors.textColor.withValues(alpha: 0.7),
                size: 24,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'features':
                    onFeaturesPressed?.call();
                    break;
                  case 'pricing':
                    onPricingPressed?.call();
                    break;
                  case 'about':
                    onAboutUsPressed?.call();
                    break;
                  case 'contact':
                    onContactPressed?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'features',
                  child: Text(l10n.features, style: TextStyle(color: colors.textColor)),
                ),
                PopupMenuItem(
                  value: 'pricing',
                  child: Text(l10n.pricing, style: TextStyle(color: colors.textColor)),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text(l10n.aboutUs, style: TextStyle(color: colors.textColor)),
                ),
                PopupMenuItem(
                  value: 'contact',
                  child: Text(l10n.contact, style: TextStyle(color: colors.textColor)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            
            // Home Icon
            GestureDetector(
              onTap: () {
                // Navigate to marketing landing page
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Icon(
                Icons.home,
                color: colors.textColor.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
          ],
        ),
        
        // Right side: Login button + Language selector
        Row(
          children: [
            // Login Button
            ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                l10n.login,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            
            // Language Selector
            _buildLanguageSelector(colors),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMenu(BuildContext context, AppColors colors, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Row(
          children: [
            GestureDetector(
              onTap: onLogoPressed,
              child: Image.asset(
                'assets/images/logo_full.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        
        // Navigation Links
        Row(
          children: [
            _buildNavLink(l10n.home, colors, onHomePressed),
            const SizedBox(width: 20),
            _buildNavLink(l10n.features, colors, onFeaturesPressed),
            const SizedBox(width: 20),
            _buildNavLink(l10n.pricing, colors, onPricingPressed),
            const SizedBox(width: 20),
            _buildNavLink(l10n.contact, colors, onContactPressed),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.login),
            ),
            const SizedBox(width: 16),
            _buildLanguageSelector(colors),
          ],
        ),
      ],
    );
  }

  Widget _buildNavLink(String text, AppColors colors, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: colors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

Widget _buildLanguageSelector(AppColors colors) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return Container(
        decoration: BoxDecoration(
          color: colors.backgroundLight,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate,
              color: colors.primaryBlue,
              size: 14,
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: AppLocalizations.of(context)!.selectLanguage,
              child: PopupMenuButton<String>(
                initialValue: themeProvider.language,
                tooltip: '', // Disable default tooltip
                color: colors.backgroundLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                offset: const Offset(5, 30),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'EN',
                    height: 30,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'EN',
                        style: TextStyle(fontSize: 12, color: colors.textColor),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'DE',
                    height: 30,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'DE',
                        style: TextStyle(fontSize: 12, color: colors.textColor),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'FR',
                    height: 30,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'FR',
                        style: TextStyle(fontSize: 12, color: colors.textColor),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'IT',
                    height: 30,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'IT',
                        style: TextStyle(fontSize: 12, color: colors.textColor),
                      ),
                    ),
                  ),
                ],
                onSelected: (String newValue) {
                  themeProvider.setLanguage(newValue);
                },
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        themeProvider.language,
                        style: TextStyle(
                          color: colors.textColor,
                          fontSize: 12,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: colors.primaryBlue,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
}