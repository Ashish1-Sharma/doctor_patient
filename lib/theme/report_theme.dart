import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

/// Centralized styles, colors, and layout constants for the printable Patient Visit Report.
class ReportTheme {
  // Brand & Accent Colors
  static const Color primaryColor = Color(0xFF0F4C81); // Medical Navy Blue
  static const Color secondaryColor = Color(0xFF1E293B); // Charcoal/Dark Slate
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color borderBlue = Color(0xFF0F4C81);
  static const Color borderLight = Color(0xFFE2E8F0); // Gray 200

  // PDF equivalents (package:pdf uses PdfColor, not Flutter's Color) — kept in
  // lock-step with the palette above so the generated PDF matches the on-screen theme.
  static const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0F4C81);
  static const PdfColor pdfSecondary = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor pdfTextMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor pdfBorderLight = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor pdfBgHeaderBar = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor pdfWhite = PdfColors.white;
  static const PdfColor pdfGreen = PdfColor.fromInt(0xFF10B981);
  
  // Backgrounds
  static const Color bgWhite = Colors.white;
  static const Color bgHeaderBar = Color(0xFFF8FAFC); // Very light slate gray for card headers

  // Icon Colors
  static const Color iconBlue = Color(0xFF3B82F6);
  static const Color iconGreen = Color(0xFF10B981);
  static const Color iconOrange = Color(0xFFF59E0B);
  
  // Spacing & Padding
  static const double pageMargin = 24.0;
  static const double sectionPadding = 16.0;
  static const double elementSpacing = 12.0;
  static const double spaceBetweenCards = 16.0;

  // Sizes & Borders
  static const double borderRadius = 8.0;
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;

  // Text Styles
  static TextStyle get clinicNameStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22.0,
        color: primaryColor,
        letterSpacing: 0.5,
      );

  static TextStyle get clinicTaglineStyle => const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
        color: textMuted,
      );

  static TextStyle get clinicContactStyle => const TextStyle(
        fontSize: 11.0,
        color: secondaryColor,
      );

  static TextStyle get reportTitleStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
        color: secondaryColor,
        letterSpacing: 1.0,
      );

  static TextStyle get cardTitleStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12.0,
        color: primaryColor,
        letterSpacing: 0.5,
      );

  static TextStyle get labelStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12.0,
        color: secondaryColor,
      );

  static TextStyle get valueStyle => const TextStyle(
        fontSize: 12.0,
        color: secondaryColor,
        height: 1.4,
      );

  static TextStyle get bodyTextStyle => const TextStyle(
        fontSize: 12.0,
        color: secondaryColor,
        height: 1.5,
      );

  static TextStyle get bulletPointStyle => const TextStyle(
        fontSize: 11.0,
        color: secondaryColor,
        height: 1.5,
      );

  static TextStyle get footerStyle => const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13.0,
        color: primaryColor,
        letterSpacing: 0.5,
      );
}
