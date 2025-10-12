import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF4285F4); // Google Blue
  static const Color primaryDark = Color(0xFF3367D6);
  static const Color primaryLight = Color(0xFF669DF6);

  // Secondary colors
  static const Color secondary = Color(0xFF34A853); // Google Green
  static const Color secondaryDark = Color(0xFF137333);
  static const Color secondaryLight = Color(0xFF81C995);

  // Accent colors
  static const Color accent = Color(0xFFEA4335); // Google Red
  static const Color accentDark = Color(0xFFD93025);
  static const Color accentLight = Color(0xFFFF7961);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Grey shades
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Ride-hailing specific colors
  static const Color pickup = Color(0xFF4CAF50); // Green for pickup
  static const Color dropoff = Color(0xFFF44336); // Red for dropoff
  static const Color route = Color(0xFF2196F3); // Blue for route
  static const Color driver = Color(0xFFFF9800); // Orange for driver

  // Social login colors
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF1877F2);
  static const Color apple = Color(0xFF000000);

  // Transparent overlays
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color lightOverlay = Color(0x40000000); // 25% black
}