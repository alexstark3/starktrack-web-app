import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 25, 25, 25),
    primary: Color(0xFF29ABE2),
    secondary: Color(0xFF67C187),
    
    error: Color(0xFFD76C6C),
  ),
  scaffoldBackgroundColor: Color.fromARGB(255, 45, 45, 45), // dark gray
  cardColor: Color.fromARGB(255, 25, 25, 25),         // <-- This is your card background in dark mode!
  dividerColor: Color.fromARGB(255, 55, 55, 55),
  extensions: <ThemeExtension<dynamic>>[
    AppColors.dark,
  ],
);
