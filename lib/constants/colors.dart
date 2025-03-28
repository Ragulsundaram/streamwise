import 'package:flutter/material.dart';

class AppColors {
  static const Color surface = Color(0xFF1E1E1E);  // Add this line
  static const Color primaryLight = Color(0xFFBDDDFC);
  static const Color primary = Color(0xFF2D94CD);
  static const Color primaryDark = Color(0xFF124A69);
  static const Color background = Color(0xFF02121E);
  
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryDark,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
    ),
  );
}