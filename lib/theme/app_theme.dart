import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color background = Color(0xFF150A21);
  static const Color surfaceContainer = Color(0xFF1E293B);
  static const Color primaryContainer = Color(0xFFFACC15);
  static const Color onPrimaryContainer = Color(0xFF6C5700);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);
  static const Color onBackground = Color(0xFFF8FAFC);
  static const Color secondaryContainer = Color(0xFF6F00BE);
  static const Color surfaceContainerHigh = Color(0xFF334155);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background, // We'll usually override this with VegaBackground
      primaryColor: primaryContainer,
      colorScheme: const ColorScheme.dark(
        primary: primaryContainer,
        onPrimary: onPrimaryContainer,
        surface: surfaceContainer,
        onSurface: onBackground,
        background: background,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: onBackground, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5), 
        displayMedium: GoogleFonts.outfit(color: onBackground, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(color: onBackground, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineSmall: GoogleFonts.outfit(color: onBackground, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        
        bodyLarge: GoogleFonts.outfit(color: onBackground, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.outfit(color: onBackground, fontSize: 14, fontWeight: FontWeight.w400),
        
        labelLarge: GoogleFonts.outfit(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelMedium: GoogleFonts.outfit(color: onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w500),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: onBackground),
        titleTextStyle: GoogleFonts.outfit(color: onBackground, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: primaryContainer.withOpacity(0.2),
        ),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryContainer, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: onSurfaceVariant.withOpacity(0.4), fontSize: 16),
        labelStyle: GoogleFonts.outfit(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
