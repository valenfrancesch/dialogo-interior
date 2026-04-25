import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sacred Palette
  static const Color sacredCream = Color(0xFFF9F6F0);
  static const Color sacredRed = Color(0xFF8B0000);
  static const Color sacredGold = Color(0xFFC5A059);
  static const Color sacredDark = Color(0xFF2C1810);

  /// Dark mode: deep warm neutrals (readable long-form text); red / gold accents unchanged.
  static const Color darkScaffold = Color(0xFF141210);
  static const Color darkSurface = Color(0xFF221C18);
  static const Color darkSurfaceContainer = Color(0xFF2C241E);
  static const Color darkSurfaceContainerHigh = Color(0xFF362E26);
  static const Color darkOnSurface = Color(0xFFF1E8DE);
  static const Color darkOutline = Color(0xFF5C4F44);
  static const Color darkPrimarySoft = Color(0xFFCC8A78);

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
      textTheme: _buildLightTextTheme(),
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: sacredRed,
        unselectedItemColor: sacredGold,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData darkTheme() {
    final baseScheme = ColorScheme.dark(
      primary: darkPrimarySoft,
      onPrimary: Colors.white,
      secondary: sacredGold,
      onSecondary: darkScaffold,
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerLow: darkSurface,
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceContainer,
      surfaceContainerHighest: darkSurfaceContainerHigh,
      outline: darkOutline,
      outlineVariant: darkOutline.withValues(alpha: 0.5),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffold,
      primaryColor: sacredRed,
      colorScheme: baseScheme,
      dividerTheme: DividerThemeData(color: sacredGold.withValues(alpha: 0.22)),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: _buildDarkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkPrimarySoft,
        ),
        iconTheme: const IconThemeData(color: darkPrimarySoft),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimarySoft,
        unselectedItemColor: sacredGold,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: darkPrimarySoft.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? darkPrimarySoft : sacredGold,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? darkPrimarySoft : sacredGold, size: 24);
        }),
      ),
    );
  }

  static TextTheme _buildLightTextTheme() {
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

  static TextTheme _buildDarkTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: sacredRed,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkOnSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: darkOnSurface.withOpacity(0.95),
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: darkOnSurface.withOpacity(0.85),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: sacredGold,
      ),
    );
  }
}
