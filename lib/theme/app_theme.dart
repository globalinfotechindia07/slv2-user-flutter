import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE53935);
  static const Color secondary = Color(0xFF1A237E);
  static const Color accent = Color(0xFF3F51B5);
  static const Color background = Color(0xFFFFF5F5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF757575);
  static const Color iconBgRed = Color(0xFFFFEBEE);
  static const Color iconBgGreen = Color(0xFFE8F5E9);
  static const Color iconBgBlue = Color(0xFFE3F2FD);
  static const Color iconBgYellow = Color(0xFFFFF8E1);
  static const Color splashBg = Color(0xFF0D1B3E);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}