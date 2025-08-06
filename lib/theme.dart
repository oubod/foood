// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // --- PALETTE (from your design system) ---
  static const Color primary = Color(0xFFFF4747);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color starRating = Color(0xFFFFC107);
  static const Color iconDefault = Color(0xFFBDBDBD);

  // --- TYPOGRAPHY (from your design system) ---
  // Using Nunito Sans as a great, modern, and readable font.
  // Add it to your pubspec.yaml if you want to use it.
  static const String fontFamily = 'Nunito Sans';

  static final TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w500, color: textPrimary),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
  );

  // --- THEME DATA ---
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      // Performance optimizations
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      cardTheme: const CardTheme(
        elevation: 0, // We use custom shadows via Container
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)), // borderRadius.large
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleLarge,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primary,
        secondary: primary,
        background: background,
        surface: surface,
      ),
    );
  }

  // Add static const definitions for accentPink and accentOrange
  static const Map<String, Color> accentPink = {
    'background': Color(0xFFF0F0F0),
    'text': Color(0xFFE53935),
  };
  static const Map<String, Color> accentOrange = {
    'background': Color(0xFFFFF8E1),
    'text': Color(0xFFFFA000),
  };
}

// --- SPACING & BORDERS (from your design system) ---
class AppConstants {
  // Colors
  static const Color primaryColor = AppTheme.primary;
  
  // Spacing
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;

  // Border Radius
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusPill = 50.0;

  // Shadows
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
