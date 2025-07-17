import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primaryBlue;
  final Color darkGray;
  final Color midGray;      // NEW: mid-range gray
  final Color lightGray;
  final Color green;
  final Color red;
  final Color dashboardBackground;
  final Color textColor;
  final Color backgroundDark;
  final Color success;
  final Color error;
  final Color whiteTextOnBlue;
  final Color orange;
  final Color sideMenuLight;
  final Color sideMenuDark;
  final Color cardColorDark;

  const AppColors({
    required this.primaryBlue,
    required this.darkGray,
    required this.midGray,
    required this.lightGray,
    required this.green,
    required this.red,
    required this.dashboardBackground,
    required this.textColor,
    required this.backgroundDark,
    required this.success,
    required this.error,
    required this.whiteTextOnBlue,
    required this.orange,
    required this.sideMenuLight,
    required this.sideMenuDark,
    required this.cardColorDark,
  });

  @override
  AppColors copyWith({
    Color? primaryBlue,
    Color? darkGray,
    Color? midGray,
    Color? lightGray,
    Color? green,
    Color? red,
    Color? dashboardBackground,
    Color? textColor,
    Color? backgroundDark,
    Color? success,
    Color? error,
    Color? whiteTextOnBlue,
    Color? orange,
    Color? sideMenuLight,
    Color? sideMenuDark,
    Color? cardColorDark,
  }) {
    return AppColors(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      darkGray: darkGray ?? this.darkGray,
      midGray: midGray ?? this.midGray,
      lightGray: lightGray ?? this.lightGray,
      green: green ?? this.green,
      red: red ?? this.red,
      dashboardBackground: dashboardBackground ?? this.dashboardBackground,
      textColor: textColor ?? this.textColor,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      success: success ?? this.success,
      error: error ?? this.error,
      whiteTextOnBlue: whiteTextOnBlue ?? this.whiteTextOnBlue,
      orange: orange ?? this.orange,
      sideMenuLight: sideMenuLight ?? this.sideMenuLight,
      sideMenuDark: sideMenuDark ?? this.sideMenuDark,
      cardColorDark: cardColorDark ?? this.cardColorDark,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      darkGray: Color.lerp(darkGray, other.darkGray, t)!,
      midGray: Color.lerp(midGray, other.midGray, t)!, // Added here
      lightGray: Color.lerp(lightGray, other.lightGray, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      dashboardBackground: Color.lerp(dashboardBackground, other.dashboardBackground, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      whiteTextOnBlue: Color.lerp(whiteTextOnBlue, other.whiteTextOnBlue, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      sideMenuLight: Color.lerp(sideMenuLight, other.sideMenuLight, t)!,
      sideMenuDark: Color.lerp(sideMenuDark, other.sideMenuDark, t)!,
      cardColorDark: Color.lerp(cardColorDark, other.cardColorDark, t)!,
    );
  }

  // Light and dark presets
  static const AppColors light = AppColors(
    primaryBlue: Color(0xFF65AAEA),
    darkGray: Color(0xFF58595B),
    midGray: Color(0xFFB0B0B0),     // Example mid gray (you can adjust this)
    lightGray: Color(0xFFEAEAEB),
    green: Color(0xFF67C187),
    red: Color(0xFFD76C6C),
    dashboardBackground: Color(0xFFF3F3F7),
    textColor: Color.fromRGBO(0, 0, 0, 1),
    backgroundDark: Color(0xFFEAEAEB),
    success: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
    whiteTextOnBlue: Colors.white,
    orange: Color(0xFFFF9800),
    sideMenuLight: Color(0xFFFFFFFF), // Light theme side menu - white
    sideMenuDark: Color(0xFFF3F3F7),  // Not used in light theme but required
    cardColorDark: Color(0xFFFFFFFF), // Light theme uses white cards
  );

  static const AppColors dark = AppColors(
    primaryBlue: Color(0xFF65AAEA),
    darkGray: Color(0xFF969696),     // VS Code secondary text
    midGray: Color(0xFF6A6A6A),      // VS Code muted text
    lightGray: Color(0xFF2D2D30),    // VS Code active elements
    green: Color(0xFF67C187),
    red: Color(0xFFD76C6C),
    dashboardBackground: Color(0xFF1E1E1E),  // VS Code background
    textColor: Color(0xFFCCCCCC),    // VS Code primary text (off-white)
    backgroundDark: Color(0xFF252526),      // VS Code sidebar
    success: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
    whiteTextOnBlue: Color(0xFFCCCCCC),      // Consistent with textColor
    orange: Color(0xFFFF9800),
    sideMenuLight: Color(0xFF252526), // Not used in dark theme but required
    sideMenuDark: Color(0xFF1E1E1E),  // VS Code side menu color
    cardColorDark: Color(0xFF191919), // Dark card color matching logs
  );
}
