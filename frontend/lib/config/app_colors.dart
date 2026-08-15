// lib/config/app_colors.dart

import 'package:flutter/material.dart';

/// Central Universal Color Palette (Refined Sports & Rally Slate System)
/// Clean Canvas (#FAFAFA), Crisp White Surface (#FFFFFF), High-Contrast Slate (#0F172A),
/// Emerald Live System (#10B981), and Precision Distress Red (#EF4444).
abstract class AppColors {
  // Brand & Core System Anchors
  static const Color primary = Color(0xFF0F172A);         // Deep Slate Ink (#0F172A)
  static const Color primaryLight = Color(0xFF1E293B);    // Slate 800 (#1E293B)
  static const Color onPrimary = Color(0xFFFFFFFF);       // Pure White (#FFFFFF)
  static const Color canvas = Color(0xFFFAFAFA);          // Off-White Clean Canvas (#FAFAFA)
  static const Color background = Color(0xFFFAFAFA);      // Canvas alias (#FAFAFA)
  static const Color softCloud = Color(0xFFF1F5F9);       // Slate 100 Surface (#F1F5F9)
  static const Color surface = Color(0xFFFFFFFF);         // Pure White Container Fill (#FFFFFF)
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Modal / Dropdown Card Fill (#FFFFFF)
  static const Color surfaceAlt = Color(0xFFF8FAFC);      // Alternating list tile (#F8FAFC)
  static const Color liveIndicatorBg = Color(0xFFECFDF5); // Emerald 50 (#ECFDF5)
  static const Color liveIndicatorText = Color(0xFF059669); // Emerald 600 (#059669)
  static const Color white = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Text Hierarchy (WCAG AAA High-Contrast)
  static const Color ink = Color(0xFF0F172A);             // Primary Headline & Body Text (#0F172A)
  static const Color textPrimary = Color(0xFF0F172A);     // Slate 900 (#0F172A)
  static const Color charcoal = Color(0xFF334155);        // Slate 700 (#334155) - High Contrast Body
  static const Color ash = Color(0xFF475569);             // Slate 600 (#475569) - Secondary Text
  static const Color mute = Color(0xFF64748B);            // Slate 500 (#64748B) - Subtitles & Metadata
  static const Color textSecondary = Color(0xFF475569);   // Slate 600
  static const Color stone = Color(0xFF94A3B8);           // Slate 400 (#94A3B8)
  static const Color textMuted = Color(0xFF64748B);       // Slate 500 (Accessible 4.8:1+)
  static const Color textInverse = Color(0xFFFFFFFF);     // White text on dark buttons (#FFFFFF)
  static const Color textWhite = Color(0xFFFFFFFF);

  // Dividers & Hairlines
  static const Color hairline = Color(0xFFE2E8F0);        // Slate 200 Hairline Border (#E2E8F0)
  static const Color hairlineSoft = Color(0xFFF1F5F9);    // Slate 100 Hairline (#F1F5F9)
  static const Color border = Color(0xFFE2E8F0);          // Container Border (#E2E8F0)
  static const Color borderLight = Color(0xFFCBD5E1);     // Crisp Slate 300 Border (#CBD5E1)
  static const Color hairlineLight = Color(0xFFE2E8F0);

  // Semantic Status (Crisp Sports Alerts)
  static const Color sale = Color(0xFFEF4444);            // SOS Alert Crimson Red (#EF4444)
  static const Color saleDeep = Color(0xFF991B1B);        // Red 800 (#991B1B)
  static const Color error = Color(0xFFEF4444);           // Error / SOS alias (#EF4444)
  static const Color errorBright = Color(0xFFF87171);     // Red 400 (#F87171)
  static const Color errorBg = Color(0xFFFEF2F2);         // Soft Red Container (#FEF2F2)
  static const Color errorBorder = Color(0xFFFECACA);     // Red 200 Border (#FECACA)
  static const Color errorAccent = Color(0xFFDC2626);     // Red 600 (#DC2626)

  static const Color success = Color(0xFF10B981);         // Emerald 500 (#10B981)
  static const Color successBright = Color(0xFF34D399);   // Emerald 400 (#34D399)
  static const Color successBg = Color(0xFFECFDF5);       // Soft Emerald Container (#ECFDF5)
  static const Color successBorder = Color(0xFFA7F3D0);   // Emerald 200 Border (#A7F3D0)

  static const Color warning = Color(0xFFF59E0B);         // Warning Amber (#F59E0B)
  static const Color warningBright = Color(0xFFFBBF24);   // Amber 400 (#FBBF24)
  static const Color warningAccent = Color(0xFFD97706);   // Deep Amber 600 (#D97706)
  static const Color warningBg = Color(0xFFFFFBEB);       // Soft Amber Container (#FFFBEB)
  static const Color warningBorder = Color(0xFFFDE68A);   // Amber 200 Border (#FDE68A)

  static const Color info = Color(0xFF2563EB);            // Blue 600 (#2563EB)
  static const Color infoDeep = Color(0xFF1D4ED8);        // Blue 700 (#1D4ED8)
  static const Color infoBg = Color(0xFFEFF6FF);          // Soft Blue Container (#EFF6FF)
  static const Color infoBorder = Color(0xFFBFDBFE);      // Blue 200 Border (#BFDBFE)

  // Category Accents
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPinkSoft = Color(0xFFFCE7F3);
  static const Color accentPurpleSoft = Color(0xFFEDE9FE);
  static const Color accentPurplePale = Color(0xFFF5F3FF);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentPinkDeep = Color(0xFF831843);

  // Density Heat Cluster Scale (Cohesive Sports Cartography)
  static const Color clusterCyan = Color(0xFF0D9488);       // Tier 1: 1-24 pax (Teal)
  static const Color clusterSkyBlue = Color(0xFF2563EB);    // Tier 2: 25-99 pax (Blue)
  static const Color clusterAmber = Color(0xFFD97706);      // Tier 3: 100-299 pax (Amber)
  static const Color clusterCoralRed = Color(0xFFEF4444);   // Tier 4: 300-599 pax (Red)
  static const Color clusterDeepPurple = Color(0xFF7E22CE); // Tier 5: 600+ pax (Purple)

  // Vector Cartography & Street Tiles
  static const Color mapBackground = Color(0xFFF8FAFC);
  static const Color mapOverlayBg = Color(0xEEFFFFFF);
  static const Color mapHeaderBg = Color(0xDDFFFFFF);
  static const Color mapLegendBg = Color(0xEEFFFFFF);
  static const Color streetGrid = Color(0xFFE2E8F0);
  static const Color streetArterial = Color(0xFFCBD5E1);
  static const Color routeLine = Color(0xFF0F172A);
  static const Color routeGlow = Color(0x220F172A);
  static const Color leaderPulse = Color(0xFF10B981);
  static const Color leaderPulseGlow = Color(0x3310B981);
  static const Color landmarkTextBg = Color(0xEEFFFFFF);
  static const Color landmarkBorder = Color(0xFF0F172A);

  // Buttons, Badges, & Chips Tokens
  static const Color buttonPrimaryBg = Color(0xFF0F172A);     // Slate 900 Pill Button
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);   // White Label
  static const Color buttonSecondaryBg = Color(0xFFF1F5F9);   // Slate 100 Pill Button
  static const Color buttonSecondaryText = Color(0xFF0F172A); // Slate 900 Label
  static const Color buttonSecondaryBorder = Color(0xFFE2E8F0);
  static const Color buttonDisabledBg = Color(0xFFF1F5F9);
  static const Color buttonDisabledText = Color(0xFF94A3B8);
}
