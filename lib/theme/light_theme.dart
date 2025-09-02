import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: Colors.white,
    primary: Color(0xFF29ABE2),
    secondary: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
  ),
  scaffoldBackgroundColor: Color(0xFFF3F3F7), // light gray,
  cardColor: Colors.white,              // <-- This is your card background!
  dividerColor: Color(0xFFE5EAF1),
  extensions: <ThemeExtension<dynamic>>[
    AppColors.light,
  ],
  // Add more ThemeData options as you like
);
