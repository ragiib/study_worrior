// ============================================================================
// App Theme - Premium Design System
// Defines light & dark themes with curated color palettes,
// typography, and component styles for a premium feel.
// ============================================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C63FF);      // Vibrant indigo
  static const Color secondaryColor = Color(0xFF00D9A6);     // Mint green accent
  static const Color accentOrange = Color(0xFFFF6B6B);       // Coral red
  static const Color accentYellow = Color(0xFFFFD93D);       // Golden yellow
  static const Color accentPurple = Color(0xFFA855F7);       // Soft purple

  // ── Dark Mode Palette ─────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0F0F23);             // Deep navy
  static const Color darkSurface = Color(0xFF1A1A3E);        // Card surface
  static const Color darkSurfaceAlt = Color(0xFF252552);     // Elevated surface
  static const Color darkText = Color(0xFFF0F0FF);           // Off-white text
  static const Color darkTextSecondary = Color(0xFF9090B0);  // Muted text

  // ── Light Mode Palette ────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF5F5FF);            // Soft lavender bg
  static const Color lightSurface = Color(0xFFFFFFFF);       // White cards
  static const Color lightSurfaceAlt = Color(0xFFEEEEFF);   // Tinted surface
  static const Color lightText = Color(0xFF1A1A3E);          // Dark navy text
  static const Color lightTextSecondary = Color(0xFF6B6B8D); // Muted text

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A3E), Color(0xFF252552)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D9A6), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        error: accentOrange,
      ),
      fontFamily: 'Inter',
      textTheme: _textTheme(lightText, lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: lightText,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceAlt,
        selectedColor: primaryColor.withAlpha(50),
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: accentOrange,
      ),
      fontFamily: 'Inter',
      textTheme: _textTheme(darkText, darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceAlt,
        selectedColor: primaryColor.withAlpha(50),
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: darkText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ── Shared Text Theme ─────────────────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }
}
