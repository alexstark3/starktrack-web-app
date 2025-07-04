import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryBlue;
  final Color darkGray;
  final Color lightGray;
  final Color green;
  final Color red;
  final Color dashboardBackground;

  // semantic aliases
  final Color textColor;
  final Color backgroundLight;
  final Color success;
  final Color error;

  const AppColors({
    required this.primaryBlue,
    required this.darkGray,
    required this.lightGray,
    required this.green,
    required this.red,
    required this.dashboardBackground,
    required this.textColor,
    required this.backgroundLight,
    required this.success,
    required this.error,
  });

  @override
  AppColors copyWith({
    Color? primaryBlue,
    Color? darkGray,
    Color? lightGray,
    Color? green,
    Color? red,
    Color? dashboardBackground,
    Color? textColor,
    Color? backgroundLight,
    Color? success,
    Color? error,
  }) {
    return AppColors(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      darkGray: darkGray ?? this.darkGray,
      lightGray: lightGray ?? this.lightGray,
      green: green ?? this.green,
      red: red ?? this.red,
      dashboardBackground: dashboardBackground ?? this.dashboardBackground,
      textColor: textColor ?? this.textColor,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      darkGray: Color.lerp(darkGray, other.darkGray, t)!,
      lightGray: Color.lerp(lightGray, other.lightGray, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      dashboardBackground: Color.lerp(dashboardBackground, other.dashboardBackground, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }

  // Light and dark presets

  static const AppColors light = AppColors(
    primaryBlue: Color(0xFF65AAEA),
    darkGray: Color(0xFF58595B),
    lightGray: Color(0xFFEAEAEB),
    green: Color(0xFF67C187),
    red: Color(0xFFD76C6C),
    dashboardBackground: Color(0xFFF3F3F7), // light gray
    textColor: Color.fromRGBO(88, 89, 91, 1),
    backgroundLight: Color(0xFFEAEAEB),
    success: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
  );

  static const AppColors dark = AppColors(
    primaryBlue: Color(0xFF65AAEA),
    darkGray: Color(0xFF58595B),
    lightGray: Color(0xFFEAEAEB),
    green: Color(0xFF67C187),
    red: Color(0xFFD76C6C),
    dashboardBackground: Color(0xFF232323), // dark gray
    textColor: Color(0xFFF3F3F7),
    backgroundLight: Color(0xFF232323),
    success: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
  );
}
