// lib/config/app_typography.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central Typography Hierarchy
/// Uses const definitions for widget const-correctness;
/// Project-wide Inter font and Noto Color Emoji fallbacks are applied via AppTheme.
abstract class AppTypography {
  // Display Campaign Tier
  static const TextStyle displayCampaign = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.ink,
    height: 1.1,
  );

  // Headings
  static const TextStyle headingXl = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle headingLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.ink,
    height: 1.25,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
    height: 1.3,
  );

  // Body
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.4,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoal,
    height: 1.4,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mute,
    height: 1.35,
  );

  // Primary Buttons (Dark / Ink background -> White text)
  static const TextStyle buttonLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  static const TextStyle buttonMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  static const TextStyle buttonSm = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  // Secondary Buttons (White / Light background -> Ink text)
  static const TextStyle buttonLgSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle buttonMdSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle buttonSmSecondary = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.ink,
    height: 1.2,
  );

  // Badges & Captions
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mute,
    height: 1.3,
  );

  static const TextStyle captionXs = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.stone,
    height: 1.2,
  );
}
