import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme defines the premium visual identity of our Doctor-Patient dashboard.
/// It uses a modern slate-blue, teal, and soft amber palette, with elegant typography.
class AppTheme {
  // Brand Colors
  static const Color primarySlate = Color(0xFF0F172A); // Slate 900
  static const Color secondarySlate = Color(0xFF475569); // Slate 600
  static const Color tealAccent = Color(0xFF0D9488); // Teal 600
  static const Color emeraldSuccess = Color(0xFF059669); // Emerald 600
  static const Color whatsappGreen = Color(0xFF25D366); // WhatsApp Green
  static const Color amberWarning = Color(0xFFD97706); // Amber 600
  static const Color redDestructive = Color(0xFFDC2626); // Red 600
  
  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color cardShadowColor = Color(0x0F0F172A); // Very soft shadow

  // Visual Gradients for Stat Cards
  static const Gradient patientCardGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Vibrant Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient appointmentCardGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Warm Amber
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient paymentCardGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)], // Refreshing Teal/Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient newTreatmentGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Dark Sleek Slate
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Custom Card Shadow Decoration
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: cardShadowColor,
          blurRadius: 16,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  // Theme Data Setup
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tealAccent,
        primary: primarySlate,
        secondary: tealAccent,
        surface: surface,
        // ignore: deprecated_member_use
        background: background,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primarySlate,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primarySlate,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primarySlate,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primarySlate,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: secondarySlate,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: secondarySlate,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primarySlate,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
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
          borderSide: const BorderSide(color: tealAccent, width: 2),
        ),
        labelStyle: TextStyle(color: secondarySlate, fontSize: 14),
        hintStyle: TextStyle(color: secondarySlate.withValues(alpha: 0.6), fontSize: 14),
      ),
    );
  }
}
