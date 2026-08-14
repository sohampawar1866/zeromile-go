// lib/config/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static const Color background = AppColors.canvas;
  static const Color surface = AppColors.softCloud;
  static const Color surfaceElevated = AppColors.surfaceElevated;
  static const Color border = AppColors.hairlineSoft;
  static const Color borderLight = AppColors.hairline;

  static const Color primary = AppColors.ink;
  static const Color primaryLight = AppColors.info;
  static const Color primaryDark = AppColors.ink;

  static const Color success = AppColors.success;
  static const Color successBg = AppColors.successBg;
  static const Color successBorder = AppColors.successBorder;

  static const Color warning = AppColors.warning;
  static const Color warningBg = AppColors.warningBg;

  static const Color error = AppColors.sale;
  static const Color errorBg = AppColors.errorBg;

  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = AppColors.mute;
  static const Color textMuted = AppColors.stone;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.softCloud,
        onPrimaryContainer: AppColors.ink,
        surface: AppColors.softCloud,
        onSurface: AppColors.ink,
        error: AppColors.sale,
        onError: AppColors.white,
        outline: AppColors.hairlineSoft,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.softCloud,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          side: BorderSide(color: AppColors.hairlineSoft, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: AppTypography.headingMd,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineSoft,
        thickness: 1.0,
        space: AppSpacing.lg,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.softCloud,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.hairlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.hairlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.ink, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        labelStyle: AppTypography.bodySm,
        hintStyle: AppTypography.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          textStyle: AppTypography.buttonMd,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.hairline),
          textStyle: AppTypography.buttonMd,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.mute,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Alias darkTheme to lightTheme so the Nike white canvas is universal
  static ThemeData get darkTheme => lightTheme;
}
