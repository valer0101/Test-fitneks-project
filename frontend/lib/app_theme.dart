// lib/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- BRAND CONSTANTS ---
  static const Color primaryOrange = Color(0xFFEC612A);
  static const Color secondaryOrange = Color(0xFFB2451D);
  // Colors for fitneksGradient
  static const Color fitneksGradientStart = Color(0xFFEC612A);
  static const Color fitneksGradientEnd = Color(0xFFB2451D);
  static const LinearGradient fitneksGradient = LinearGradient(
    colors: [fitneksGradientStart, fitneksGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const Color backgroundWhite = Colors.white;
  static const Color textGrey = Color(0xFF6B7280);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const double borderRadiusLarge = 30.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double paddingMedium = 16.0;
  static const double paddingSmall = 8.0;
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color facebookBlue = Color(0xFF3B5998);
  static const Color shakesBlue = Color(0xFF1A33F0);
  static const LinearGradient shakesBlueGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF6274FF), // start
      Color(0xFF001BEA), // end
    ],
  );

 static const Color proteinColor = Color(0xFF46AF1F);
 static const Color boosticonColor = Color(0xFF331B6A);

 static const Color challengeColor = Color(0xFF001BEA);

  // --- TEXT STYLES ---
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: textPrimary, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: textSecondary, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textLight, // <-- FIX: Removed 'AppColors.'
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle logo = TextStyle(
    // The fontFamily is now removed
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
  );

  // --- THEME DATA BUILDER ---
  static ThemeData get lightTheme {
    return ThemeData(
      textTheme: GoogleFonts.openSansTextTheme(),
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: secondaryOrange,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryOrange,
          side: const BorderSide(color: borderGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(
            color: primaryOrange,
            width: 2,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
