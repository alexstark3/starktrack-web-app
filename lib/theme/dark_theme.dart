import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Colors.black,
    primary: Color(0xFF65AAEA),
    secondary: Color(0xFF67C187),
    error: Color(0xFFD76C6C),
  ),
  scaffoldBackgroundColor: Color(0xFF232323), // dark gray
  extensions: <ThemeExtension<dynamic>>[
    AppColors.dark,
  ],
);
