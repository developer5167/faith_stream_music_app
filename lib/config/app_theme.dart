import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- THE DEFINITIVE FAITHSTREAM PALETTE ---
  static const Color brandIndigo = Color(0xFF040B1F);     // Base Background
  static const Color brandMagenta = Color(0xFFD946EF);    // Accent Highlights
  static const Color brandPurple = Color(0xFF8B5CF6);     // Gradient Depth
  static const Color brandSurface = Color(0xFF0F172A);    // Input Surfaces
  
  static const Color darkPrimary = Colors.white;          // High Clarity Interaction
  static const Color darkSecondary = brandMagenta;
  static const Color darkBackground = brandIndigo;
  static const Color darkSurface = brandSurface;
  static const Color darkError = Color(0xFFF43F5E);

  // Smooth, Cinematic Gradients
  static const LinearGradient premiumDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E1065), // Deep Royal Purple
      Color(0xFF040B1F), // Deep Indigo
      Color(0xFF040B1F),
    ],
    stops: [0.0, 0.4, 1.0],
  );

  static const LinearGradient freeDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF040B1F),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
  );

  // Compatibility Aliases (Pointing to Dark Theme)
  static const Color lightPrimary = darkPrimary;
  static const Color lightSecondary = darkSecondary;
  static const Color lightBackground = darkBackground;
  static const Color lightSurface = darkSurface;
  static const Color lightError = darkError;

  // Premium Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      error: darkError,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.black,
    ),

    // Typography - Clean & Modern
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // AppBar Theme - Transparent/Glass effect usually handled in widget, but defaults here
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0, // Flat for modern look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      color: Colors.white.withValues(alpha: 0.05),
      margin: EdgeInsets.zero,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white24),
    ),

    // Elevated Button Theme - Premium "Apple Dark" style
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: brandIndigo, // Clean contrast
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),

    // Custom Icon Button or Play Button styles would commonly be used in widgets
    iconTheme: const IconThemeData(color: Colors.white, size: 24),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: brandIndigo,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.normal,
      ),
      elevation: 0,
    ),
  );
}
