
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VSCodeColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1E1E1E); // Main editor background
  static const Color darkSidebar = Color(0xFF252526);    // Sidebar/Panel background
  static const Color darkActivityBar = Color(0xFF333333);// Activity Bar
  static const Color darkInput = Color(0xFF3C3C3C);      // Input field background
  static const Color darkBorder = Color(0xFF454545);     // Borders/Dividers
  static const Color darkText = Color(0xFFCCCCCC);       // Primary text
  static const Color darkTextSecondary = Color(0xFF969696); // Secondary/Comment text
  static const Color darkSelection = Color(0xFF264F78);  // Text selection
  static const Color darkHover = Color(0xFF2A2D2E);      // List item hover

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFF3F3F3);
  static const Color lightActivityBar = Color(0xFF2C2C2C); // VS Code light uses dark activity bar often, or light gray. Let's use light gray #2c2c2c is dark.
  // Actually VS Code Light default: Activity bar is #2c2c2c (Dark gray), Side bar is #f3f3f3.
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E4E4); // or #CECECE
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color lightSelection = Color(0xFFADD6FF);
  static const Color lightHover = Color(0xFFE8E8E8);

  // Shared Accents
  static const Color accentBlue = Color(0xFF007ACC);     // VS Code Blue
  static const Color accentGreen = Color(0xFF4EC9B0);    // Class/Type colorish (or Success)
  static const Color accentOrange = Color(0xFFCE9178);   // String colorish (or Warning)
  static const Color accentRed = Color(0xFFF14C4C);      // Error
  static const Color statusBarPurple = Color(0xFF68217A); // Debugging color sometimes
}

class VSCodeTheme {
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    final baseFont = GoogleFonts.firaCode(); // Monospace for developer feel
    final uiFont = GoogleFonts.inter();      // UI elements

    return TextTheme(
      displayLarge: uiFont.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
      displayMedium: uiFont.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
      bodyLarge: uiFont.copyWith(fontSize: 14, color: primaryColor),
      bodyMedium: uiFont.copyWith(fontSize: 13, color: primaryColor), // Standard UI size
      bodySmall: uiFont.copyWith(fontSize: 12, color: secondaryColor),
      labelLarge: uiFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
      labelMedium: uiFont.copyWith(fontSize: 11, color: secondaryColor),
    ).apply(
      fontFamily: uiFont.fontFamily,
      bodyColor: primaryColor,
      displayColor: primaryColor,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VSCodeColors.darkBackground,
      canvasColor: VSCodeColors.darkSidebar, // For drawers/panels
      cardColor: VSCodeColors.darkSidebar,
      dividerColor: VSCodeColors.darkBorder,
      primaryColor: VSCodeColors.accentBlue,
      
      colorScheme: const ColorScheme.dark(
        primary: VSCodeColors.accentBlue,
        secondary: VSCodeColors.accentBlue,
        surface: VSCodeColors.darkSidebar,
        error: VSCodeColors.accentRed,
        onSurface: VSCodeColors.darkText,
      ),

      textTheme: _buildTextTheme(VSCodeColors.darkText, VSCodeColors.darkTextSecondary),
      
      appBarTheme: AppBarTheme(
        backgroundColor: VSCodeColors.darkActivityBar, // Distinct toolbar
        foregroundColor: const Color(0xFFCCCCCC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFCCCCCC)),
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFCCCCCC)),
      ),

      iconTheme: const IconThemeData(
        color: VSCodeColors.darkTextSecondary,
        size: 16, // VS Code icons are often small
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VSCodeColors.darkInput,
        hoverColor: VSCodeColors.darkHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Compact
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2), // Sharp corners
          borderSide: const BorderSide(color: VSCodeColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: VSCodeColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: VSCodeColors.accentBlue),
        ),
        hintStyle: GoogleFonts.inter(color: VSCodeColors.darkTextSecondary, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VSCodeColors.darkText,
          textStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: VSCodeColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      
      // TabBar style via simple override, but custom widgets might be needed for full VS Code look
      tabBarTheme: TabBarThemeData(
        labelColor: VSCodeColors.darkText,
        unselectedLabelColor: VSCodeColors.darkTextSecondary,
        indicatorColor: VSCodeColors.accentBlue,
        dividerColor: VSCodeColors.darkBorder,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VSCodeColors.lightBackground,
      canvasColor: VSCodeColors.lightSidebar,
      cardColor: VSCodeColors.lightSidebar,
      dividerColor: VSCodeColors.lightBorder,
      primaryColor: VSCodeColors.accentBlue,

      colorScheme: const ColorScheme.light(
        primary: VSCodeColors.accentBlue,
        secondary: VSCodeColors.accentBlue,
        surface: VSCodeColors.lightSidebar,
        error: VSCodeColors.accentRed,
        onSurface: VSCodeColors.lightText,
      ),

      textTheme: _buildTextTheme(VSCodeColors.lightText, VSCodeColors.lightTextSecondary),

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFDDDDDD), // Light activity bar equivalent
        foregroundColor: VSCodeColors.lightText,
        elevation: 0,
        iconTheme: const IconThemeData(color: VSCodeColors.lightText),
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: VSCodeColors.lightText),
      ),

      iconTheme: const IconThemeData(
        color: VSCodeColors.lightTextSecondary,
        size: 16,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VSCodeColors.lightInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: VSCodeColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: VSCodeColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: VSCodeColors.accentBlue),
        ),
        hintStyle: GoogleFonts.inter(color: VSCodeColors.lightTextSecondary, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      
       textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VSCodeColors.lightText,
          textStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: VSCodeColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: VSCodeColors.lightText,
        unselectedLabelColor: VSCodeColors.lightTextSecondary,
        indicatorColor: VSCodeColors.accentBlue,
        dividerColor: VSCodeColors.lightBorder,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }
}
