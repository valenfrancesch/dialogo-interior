import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sacred Palette
  static const Color sacredCream = Color(0xFFF9F6F0);
  static const Color sacredRed = Color(0xFF8B0000);
  static const Color sacredGold = Color(0xFFC5A059);
  static const Color sacredDark = Color(0xFF2C1810);

  // Legacy mappings for compatibility
  static const Color primaryDarkBg = sacredCream; 
  static const Color accentMint = sacredRed;      
  static const Color accentPurple = sacredGold;   
  static const Color cardDark = Colors.white;     
  static const Color surfaceDark = sacredCream;   

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sacredCream,
      primaryColor: sacredRed,
      colorScheme: ColorScheme.light(
        primary: sacredRed,
        secondary: sacredGold,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: sacredDark,
        onSurface: sacredDark.withOpacity(0.9),
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: sacredRed,
        ),
        iconTheme: const IconThemeData(color: sacredRed),
      ),
    );
  }

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