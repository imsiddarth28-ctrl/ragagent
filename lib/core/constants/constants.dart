import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF4F46E5);       // Indigo 600 - vibrant, modern
  static const Color primaryDark = Color(0xFF4338CA);   // Indigo 700
  static const Color primaryLight = Color(0xFF6366F1);  // Indigo 500
  static const Color primaryTint = Color(0xFFEEF2FF);   // Indigo 50 - soft chip/card tint

  // Semantic & Secondary
  static const Color secondary = Color(0xFF059669);     // Emerald 600 - vibrant success
  static const Color secondaryTint = Color(0xFFECFDF5); // Emerald 50
  static const Color accent = Color(0xFFF59E0B);        // Amber 500
  static const Color accentTint = Color(0xFFFEF3C7);    // Amber 50
  static const Color error = Color(0xFFDC2626);         // Red 600
  static const Color errorTint = Color(0xFFFEF2F2);     // Red 50

  // Light Theme Surfaces & Text (Optimized for clean, crisp light mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Pure White
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);     // Slate 200
  static const Color inputFillLight = Color(0xFFF1F5F9);  // Slate 100
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900 - crisp, sharp
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8);     // Slate 400

  // Dark Theme Surfaces & Text
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color inputFillDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
}
