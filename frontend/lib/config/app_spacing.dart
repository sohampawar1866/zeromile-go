// lib/config/app_spacing.dart

import 'package:flutter/material.dart';

/// Universal 8px-based spacing and border radius tokens
abstract class AppSpacing {
  // Spacing Scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double section = 48.0;

  // Insets
  static const EdgeInsets edgeInsetsScreen = EdgeInsets.all(16.0);
  static const EdgeInsets edgeInsetsCard = EdgeInsets.all(18.0);
  static const EdgeInsets edgeInsetsPill = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets edgeInsetsBadge = EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);
  static const EdgeInsets edgeInsetsDialog = EdgeInsets.all(24.0);
}

abstract class AppRadius {
  static const double none = 0.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double pill = 30.0;
  static const double full = 9999.0;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}
