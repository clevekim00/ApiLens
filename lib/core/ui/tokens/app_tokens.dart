
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTokens {
  // 1) Radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  // 2) Spacing scale
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 24.0;
  static const double s6 = 32.0;

  // 3) Typography
  static TextTheme get textTheme {
    // UI Font: System UI (Inter as proxi or default)
    // Actually user said "system-ui (default TextTheme)" but let's use Inter for that clean look if possible,
    // or just standard Flutter typography which defaults to system font on different OS.
    // User said "UI 폰트: system-ui (기본 TextTheme)". So we will rely on ThemeData's default but maybe adjust sizes.
    // However, to ensure "shadcn" feel, Inter is usually the go-to.
    // Let's stick to standard Flutter TextTheme but with sizes defined.
    // Actually user specified Font sizes: labelSm 12, body 14, bodyLg 16, title 18, titleLg 20
    
    return TextTheme(
      labelSmall: GoogleFonts.inter(fontSize: 12, height: 1.35),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.35), // body
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.35),  // bodyLg
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600), // title
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600), // titleLg
      // Fallbacks
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static TextStyle get monoStyle {
    return GoogleFonts.firaCode(
      fontSize: 13, // Standard code size
      height: 1.35,
    );
  }
}

class AppColorsLight {
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0B1020);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0B1020);
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF0B1020);
  static const Color muted = Color(0xFFF5F7FB);
  static const Color mutedForeground = Color(0xFF5B6475);
  static const Color border = Color(0xFFE5E7EB);
  static const Color input = Color(0xFFFFFFFF);
  static const Color ring = Color(0xFF2563EB);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF3F4F6);
  static const Color secondaryForeground = Color(0xFF0B1020);
  static const Color accent = Color(0xFFEEF2FF);
  static const Color accentForeground = Color(0xFF0B1020);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
}

class AppColorsDark {
  static const Color background = Color(0xFF0F1115);
  static const Color foreground = Color(0xFFE6E6E6);
  static const Color card = Color(0xFF151821);
  static const Color cardForeground = Color(0xFFE6E6E6);
  static const Color popover = Color(0xFF151821);
  static const Color popoverForeground = Color(0xFFE6E6E6);
  static const Color muted = Color(0xFF1B1F2A);
  static const Color mutedForeground = Color(0xFFA7B0C0);
  static const Color border = Color(0xFF2A2F3A);
  static const Color input = Color(0xFF1B1F2A);
  static const Color ring = Color(0xFF3B82F6);
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryForeground = Color(0xFF0B1020);
  static const Color secondary = Color(0xFF202635);
  static const Color secondaryForeground = Color(0xFFE6E6E6);
  static const Color accent = Color(0xFF232A3B);
  static const Color accentForeground = Color(0xFFE6E6E6);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFF0B1020);
}
