import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF07070C);
  static const surface = Color(0xFF121218);
  static const surfaceAlt = Color(0xFF1A1A22);
  static const stroke = Color(0xFF252531);
  static const accent = Color(0xFFF51C5B);
  static const accentSoft = Color(0xFF4A1424);
  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFFA6A7BB);
  static const gold = Color(0xFFF8C947);
  static const success = Color(0xFF16C784);
  static const danger = Color(0xFFFF627D);
}

ThemeData buildCineBookTheme() {
  final baseTheme = ThemeData.dark();

  return baseTheme.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.gold,
      surface: AppColors.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceAlt,
      contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: baseTheme.textTheme.copyWith(
      displaySmall: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 38,
        fontWeight: FontWeight.w800,
        height: 1.05,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      titleLarge: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: AppColors.stroke,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: Color(0x66FFFFFF)),
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
