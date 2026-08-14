// lib/config/app_colors.dart

import 'package:flutter/material.dart';

/// Central Universal Color Palette
/// Pure White Canvas (#FFFFFF), Soft Cloud (#F5F5F5), Deep Ink (#111111),
/// and semantic accents (Alert Red, Success Green, Info Blue).
abstract class AppColors {
  // Brand & Core System Anchors
  static const Color primary = Color(0xFF111111);         // Deep Ink (#111111)
  static const Color primaryLight = Color(0xFF333333);    // Primary Light (#333333)
  static const Color onPrimary = Color(0xFFFFFFFF);       // Pure White (#FFFFFF)
  static const Color canvas = Color(0xFFFFFFFF);          // Main Page Background (#FFFFFF)
  static const Color background = Color(0xFFFFFFFF);      // Canvas alias (#FFFFFF)
  static const Color softCloud = Color(0xFFF5F5F5);       // Soft Cloud (#F5F5F5) Surface
  static const Color surface = Color(0xFFF5F5F5);         // Card & Container Fill (#F5F5F5)
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Modal / Dropdown Card Fill (#FFFFFF)
  static const Color surfaceAlt = Color(0xFFEEEEEE);      // Alternating list tile (#EEEEEE)
  static const Color liveIndicatorBg = Color(0xFFE8F5E9);
  static const Color liveIndicatorText = Color(0xFF007D48);
  static const Color white = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Text Hierarchy
  static const Color ink = Color(0xFF111111);             // Primary Headline & Body Text (#111111)
  static const Color textPrimary = Color(0xFF111111);     // Primary Text (#111111)
  static const Color charcoal = Color(0xFF39393B);        // Secondary Body (#39393B)
  static const Color ash = Color(0xFF4B4B4D);             // Low-emphasis Text (#4B4B4D)
  static const Color mute = Color(0xFF707072);            // Subtitle & Metadata (#707072)
  static const Color textSecondary = Color(0xFF707072);   // Muted Secondary Text (#707072)
  static const Color stone = Color(0xFF9E9EA0);           // Utility metadata (#9E9EA0)
  static const Color textMuted = Color(0xFF9E9EA0);       // Low-emphasis Muted Text (#9E9EA0)
  static const Color textInverse = Color(0xFFFFFFFF);     // White text on dark buttons (#FFFFFF)
  static const Color textWhite = Color(0xFFFFFFFF);

  // Dividers & Hairlines
  static const Color hairline = Color(0xFFCACACB);        // 1px Hairline Border (#CACACB)
  static const Color hairlineSoft = Color(0xFFE5E5E5);    // Soft 1px Hairline (#E5E5E5)
  static const Color border = Color(0xFFE5E5E5);          // Container Border (#E5E5E5)
  static const Color borderLight = Color(0xFFCACACB);     // Crisp Border (#CACACB)
  static const Color hairlineLight = Color(0xFFCACACB);

  // Semantic Status
  static const Color sale = Color(0xFFD30005);            // SOS Alert Red (#D30005)
  static const Color saleDeep = Color(0xFF780700);        // Pressed Alert Red (#780700)
  static const Color error = Color(0xFFD30005);           // Error / SOS alias (#D30005)
  static const Color errorBright = Color(0xFFEF4444);     // Bright Red (#EF4444)
  static const Color errorBg = Color(0xFFFEE2E2);         // Soft Red Container (#FEE2E2)
  static const Color errorBorder = Color(0xFFFCA5A5);     // Red Border (#FCA5A5)
  static const Color errorAccent = Color(0xFFD30005);

  static const Color success = Color(0xFF007D48);         // Success Green (#007D48)
  static const Color successBright = Color(0xFF1EAA52);   // Bright Success Green (#1EAA52)
  static const Color successBg = Color(0xFFE8F5E9);       // Soft Green Container (#E8F5E9)
  static const Color successBorder = Color(0xFFA5D6A7);   // Green Border (#A5D6A7)

  static const Color warning = Color(0xFFF59E0B);         // Warning Amber (#F59E0B)
  static const Color warningBright = Color(0xFFD97706);   // Bright Amber (#D97706)
  static const Color warningAccent = Color(0xFFB45309);   // Deep Amber (#B45309)
  static const Color warningBg = Color(0xFFFEF3C7);       // Soft Amber Container (#FEF3C7)
  static const Color warningBorder = Color(0xFFFCD34D);   // Amber Border (#FCD34D)

  static const Color info = Color(0xFF1151FF);            // Broadcast / Live Blue (#1151FF)
  static const Color infoDeep = Color(0xFF0034E3);        // Deep Royal Blue (#0034E3)
  static const Color infoBg = Color(0xFFDBEAFE);          // Soft Blue Container (#DBEAFE)
  static const Color infoBorder = Color(0xFF93C5FD);      // Blue Border (#93C5FD)

  // Category Accents
  static const Color accentPink = Color(0xFFED1AA0);
  static const Color accentPinkSoft = Color(0xFFFFB0DD);
  static const Color accentPurpleSoft = Color(0xFFBEAFFD);
  static const Color accentPurplePale = Color(0xFFD6D1FF);
  static const Color accentTeal = Color(0xFF0A7281);
  static const Color accentPinkDeep = Color(0xFF4C012D);

  // Density Heat Cluster Scale
  static const Color clusterCyan = Color(0xFF0A7281);       // Tier 1: 1-24 pax (Teal)
  static const Color clusterSkyBlue = Color(0xFF1151FF);    // Tier 2: 25-99 pax (Blue)
  static const Color clusterAmber = Color(0xFFD97706);      // Tier 3: 100-299 pax (Amber)
  static const Color clusterCoralRed = Color(0xFFD30005);   // Tier 4: 300-599 pax (Red)
  static const Color clusterDeepPurple = Color(0xFF4C012D); // Tier 5: 600+ pax (Deep)

  // Vector Cartography & Street Tiles (Clean White/Soft-Cloud Canvas)
  static const Color mapBackground = Color(0xFFF5F5F5);
  static const Color mapOverlayBg = Color(0xEEFFFFFF);
  static const Color mapHeaderBg = Color(0xDDFFFFFF);
  static const Color mapLegendBg = Color(0xEEFFFFFF);
  static const Color streetGrid = Color(0xFFE5E5E5);
  static const Color streetArterial = Color(0xFFCACACB);
  static const Color routeLine = Color(0xFF111111);
  static const Color routeGlow = Color(0x33111111);
  static const Color leaderPulse = Color(0xFF007D48);
  static const Color leaderPulseGlow = Color(0x44007D48);
  static const Color landmarkTextBg = Color(0xEEFFFFFF);
  static const Color landmarkBorder = Color(0xFF111111);

  // Buttons, Badges, & Chips Tokens
  static const Color buttonPrimaryBg = Color(0xFF111111);     // Black Pill Button
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);   // White Label
  static const Color buttonSecondaryBg = Color(0xFFF5F5F5);   // Soft Gray Pill Button
  static const Color buttonSecondaryText = Color(0xFF111111); // Ink Label
  static const Color buttonSecondaryBorder = Color(0xFFE5E5E5);
  static const Color buttonDisabledBg = Color(0xFFE5E5E5);
  static const Color buttonDisabledText = Color(0xFF9E9EA0);
}
