
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
    return TextTheme(
      labelSmall: _uiStyle(fontSize: 12, height: 1.35),
      bodyMedium: _uiStyle(fontSize: 14, height: 1.35),
      bodyLarge: _uiStyle(fontSize: 16, height: 1.35),
      titleMedium: _uiStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: _uiStyle(fontSize: 20, fontWeight: FontWeight.w600),
      labelMedium: _uiStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static TextStyle get monoStyle {
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.firaCode(
        fontSize: 13,
        height: 1.35,
      );
    }

    return const TextStyle(
      fontSize: 13,
      height: 1.35,
      fontFamily: 'monospace',
    );
  }

  static TextStyle _uiStyle({
    double? fontSize,
    double? height,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        color: color,
      );
    }

    return TextStyle(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      color: color,
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
