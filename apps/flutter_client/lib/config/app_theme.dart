import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF073B6F);
  static const deepNavy = Color(0xFF062E58);
  static const blue = Color(0xFF087EEA);
  static const teal = Color(0xFF16A6B6);
  static const canvas = Color(0xFFF7FAFD);
  static const panel = Colors.white;
  static const paleBlue = Color(0xFFF0F7FC);
  static const border = Color(0xFFD8E5EE);
  static const textPrimary = Color(0xFF16324F);
  static const textSecondary = Color(0xFF687D91);
  static const success = Color(0xFF0EAA7B);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.navy,
      secondary: AppColors.teal,
      surface: AppColors.panel,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Segoe UI',
      dividerColor: AppColors.border,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.panel,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
        ),
      ),
    );
  }
}
