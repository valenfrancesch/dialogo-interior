import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sacred Palette
  static const Color sacredCream = Color(0xFFF9F6F0);
  static const Color sacredRed = Color(0xFF8B0000);
  static const Color sacredGold = Color(0xFFC5A059);
  static const Color sacredGoldLight = Color(0xFFE5D1A0);
  static const Color sacredDark = Color(0xFF2C1810);

  // Legacy mappings for compatibility
  static const Color primaryDarkBg = sacredCream; // Was Dark, now Light/Cream
  static const Color accentMint = sacredRed;      // High contrast accent
  static const Color accentPurple = sacredGold;   // Secondary accent
  static const Color accentBlue = sacredGoldLight;// Tertiary accent
  static const Color cardDark = Colors.white;     // Cards are white on cream
  static const Color surfaceDark = sacredCream;   // Surface matches bg

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sacredCream,
      primaryColor: sacredRed,
      colorScheme: ColorScheme.light(
        primary: sacredRed,
        secondary: sacredGold,
        tertiary: sacredGoldLight,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: sacredDark,
        onSurface: sacredDark.withOpacity(0.9),
        background: sacredCream,
        onBackground: sacredDark,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: sacredRed, // Red title
        ),
        iconTheme: const IconThemeData(color: sacredRed),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: sacredGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: sacredGold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: sacredRed, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: sacredDark.withOpacity(0.4),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: sacredRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: sacredRed,
        unselectedItemColor: sacredGold,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: sacredRed,
        unselectedLabelColor: sacredGold,
        indicatorColor: sacredRed,
      ),
    );
  }

  // Keep this for now to match main.dart call, but return the light theme
  static ThemeData darkTheme() => lightTheme();

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: sacredRed,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: sacredDark,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: sacredDark.withOpacity(0.9),
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: sacredDark.withOpacity(0.8),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: sacredRed,
      ),
    );
  }
}