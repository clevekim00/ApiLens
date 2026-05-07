import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTokens {
  // 1) Radius
  static const double radiusSm = 6.0;
  static const double radiusMd =
      12.0; // AntiGravity uses 12px for primary components
  static const double radiusLg = 16.0;

  // 2) Spacing scale
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 24.0;
  static const double s6 = 32.0;

  // 3) Typography
  static TextTheme get textTheme {
    return TextTheme(
      labelSmall: _uiStyle(fontSize: 12, height: 1.0, letterSpacing: 0.1),
      bodyMedium: _uiStyle(fontSize: 14, height: 1.6, letterSpacing: 0.01),
      bodyLarge: _uiStyle(fontSize: 16, height: 1.6, letterSpacing: 0.01),
      titleMedium: _uiStyle(
          fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.03),
      titleLarge: _uiStyle(
          fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: 0.03),
      labelMedium: _uiStyle(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );
  }

  static TextStyle get monoStyle {
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 1.5,
        letterSpacing: 0.5,
      );
    }

    return const TextStyle(
      fontSize: 14,
      height: 1.5,
      letterSpacing: 0.5,
      fontFamily: 'monospace',
    );
  }

  static TextStyle _uiStyle({
    double? fontSize,
    double? height,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return TextStyle(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
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
  static const Color background = Color(0xFF0B1326);
  static const Color foreground = Color(0xFFDAE2FD);
  static const Color card = Color(0xFF171F33);
  static const Color cardForeground = Color(0xFFDAE2FD);
  static const Color popover = Color(0xFF222A3D);
  static const Color popoverForeground = Color(0xFFDAE2FD);
  static const Color muted = Color(0xFF131B2E);
  static const Color mutedForeground = Color(0xFF958EA0);
  static const Color border = Color(0xFF2D3449);
  static const Color input = Color(0xFF131B2E);
  static const Color ring = Color(0xFF4CD7F6);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryForeground = Color(0xFF003640);
  static const Color accent = Color(0xFF2D3449);
  static const Color accentForeground = Color(0xFFDAE2FD);
  static const Color destructive = Color(0xFFFFB4AB);
  static const Color destructiveForeground = Color(0xFF690005);
}
