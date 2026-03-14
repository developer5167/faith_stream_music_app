import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- THE DEFINITIVE FAITHSTREAM PALETTE ---
  static const Color brandIndigo = Color(0xFF040B1F); // Base Background
  static const Color brandMagenta = Color(0xFFD946EF); // Accent Highlights
  static const Color brandPurple = Color(0xFF8B5CF6); // Gradient Depth
  static const Color brandSurface = Color(0xFF0F172A); // Input Surfaces

  static const Color darkPrimary = Colors.white; // High Clarity Interaction
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
    colors: [Color(0xFF0F172A), Color(0xFF040B1F)],
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

    // AppBar Theme - Transparent/Glass effect usually handled in widget, but defaults here
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.figtree(
        fontSize: 22,
        fontWeight: FontWeight.w700,
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

    // Base Typography - Unified Spotify-style Figtree
    textTheme: GoogleFonts.figtreeTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.figtree(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.figtree(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineMedium: GoogleFonts.figtree(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.figtree(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.figtree(
        color: Colors.white70,
        fontSize: 15,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.figtree(
        color: Colors.white60,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.figtree(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
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
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.figtree(color: Colors.white70),
      hintStyle: GoogleFonts.figtree(color: Colors.white24),
    ),

    // Elevated Button Theme - Premium "Apple Dark" style
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: brandIndigo, // Clean contrast
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
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
      selectedLabelStyle: GoogleFonts.figtree(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: GoogleFonts.figtree(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      ),
      elevation: 0,
    ),
  );
}
