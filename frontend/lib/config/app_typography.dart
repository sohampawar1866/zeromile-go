// lib/config/app_typography.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central Typography Hierarchy
/// Uses const definitions for widget const-correctness;
/// Fully compliant with WCAG 2.1 mobile outdoor glanceability guidelines.
abstract class AppTypography {
  // Display Campaign Tier
  static const TextStyle displayCampaign = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.ink,
    height: 1.15,
  );

  // Headings
  static const TextStyle headingXl = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
    height: 1.25,
  );

  static const TextStyle headingLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.ink,
    height: 1.3,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
    height: 1.35,
  );

  // Body Hierarchy
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.45,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoal,
    height: 1.45,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoal,
    height: 1.4,
  );

  // Primary Buttons (Dark / Slate background -> White text)
  static const TextStyle buttonLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  static const TextStyle buttonMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  static const TextStyle buttonSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  // Secondary Buttons (Light background -> Slate text)
  static const TextStyle buttonLgSecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle buttonMdSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle buttonSmSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.ink,
    height: 1.2,
  );

  // Badges & Captions (High Glanceability)
  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mute,
    height: 1.35,
  );

  static const TextStyle captionXs = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    height: 1.3,
  );
}
