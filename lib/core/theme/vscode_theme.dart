import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VSCodeColors {
  // Dark Theme Colors
  static const Color darkBackground =
      Color(0xFF1E1E1E); // Main editor background
  static const Color darkSidebar =
      Color(0xFF252526); // Sidebar/Panel background
  static const Color darkActivityBar = Color(0xFF333333); // Activity Bar
  static const Color darkInput = Color(0xFF3C3C3C); // Input field background
  static const Color darkBorder = Color(0xFF454545); // Borders/Dividers
  static const Color darkText = Color(0xFFCCCCCC); // Primary text
  static const Color darkTextSecondary =
      Color(0xFF969696); // Secondary/Comment text
  static const Color darkSelection = Color(0xFF264F78); // Text selection
  static const Color darkHover = Color(0xFF2A2D2E); // List item hover

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFF3F3F3);
  static const Color lightActivityBar = Color(
      0xFF2C2C2C); // VS Code light uses dark activity bar often, or light gray. Let's use light gray #2c2c2c is dark.
  // Actually VS Code Light default: Activity bar is #2c2c2c (Dark gray), Side bar is #f3f3f3.
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E4E4); // or #CECECE
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color lightSelection = Color(0xFFADD6FF);
  static const Color lightHover = Color(0xFFE8E8E8);

  // Shared Accents
  static const Color accentBlue = Color(0xFF007ACC); // VS Code Blue
  static const Color accentGreen =
      Color(0xFF4EC9B0); // Class/Type colorish (or Success)
  static const Color accentOrange =
      Color(0xFFCE9178); // String colorish (or Warning)
  static const Color accentRed = Color(0xFFF14C4C); // Error
  static const Color statusBarPurple =
      Color(0xFF68217A); // Debugging color sometimes
}

class VSCodeTheme {
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    final uiFont = _uiStyle();

    return TextTheme(
      displayLarge: uiFont.copyWith(
          fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
      displayMedium: uiFont.copyWith(
          fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
      bodyLarge: uiFont.copyWith(fontSize: 14, color: primaryColor),
      bodyMedium: uiFont.copyWith(
          fontSize: 13, color: primaryColor), // Standard UI size
      bodySmall: uiFont.copyWith(fontSize: 12, color: secondaryColor),
      labelLarge: uiFont.copyWith(
          fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
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
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      scaffoldBackgroundColor: VSCodeColors.darkBackground,
      canvasColor: VSCodeColors.darkSidebar, // For drawers/panels
      cardColor: VSCodeColors.darkSidebar,
      dividerColor: VSCodeColors.darkBorder,
      primaryColor: VSCodeColors.accentBlue,

      colorScheme: const ColorScheme.dark(
        primary: VSCodeColors.accentBlue,
        onPrimary: Colors.white,
        secondary: VSCodeColors.accentBlue,
        onSecondary: Colors.white,
        surface: VSCodeColors.darkSidebar,
        error: VSCodeColors.accentRed,
        onSurface: VSCodeColors.darkText,
      ),

      textTheme: _buildTextTheme(
          VSCodeColors.darkText, VSCodeColors.darkTextSecondary),

      appBarTheme: AppBarTheme(
        backgroundColor: VSCodeColors.darkActivityBar, // Distinct toolbar
        foregroundColor: const Color(0xFFCCCCCC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFCCCCCC)),
        titleTextStyle: _uiStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFCCCCCC)),
      ),

      iconTheme: const IconThemeData(
        color: VSCodeColors.darkTextSecondary,
        size: 16, // VS Code icons are often small
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VSCodeColors.darkInput,
        hoverColor: VSCodeColors.darkHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Compact
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
        hintStyle:
            _uiStyle(color: VSCodeColors.darkTextSecondary, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(64, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VSCodeColors.darkText,
          side: const BorderSide(color: VSCodeColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(64, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VSCodeColors.darkText,
          textStyle: _uiStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: VSCodeColors.darkBorder),
      ),

      listTileTheme: const ListTileThemeData(
        dense: true,
        minLeadingWidth: 20,
        horizontalTitleGap: 8,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: VSCodeColors.darkSidebar,
        surfaceTintColor: Colors.transparent,
        textStyle: _uiStyle(fontSize: 13, color: VSCodeColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: VSCodeColors.darkBorder),
        ),
        textStyle: _uiStyle(fontSize: 12, color: VSCodeColors.darkText),
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
        labelStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _uiStyle(fontSize: 13),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      scaffoldBackgroundColor: VSCodeColors.lightBackground,
      canvasColor: VSCodeColors.lightSidebar,
      cardColor: VSCodeColors.lightSidebar,
      dividerColor: VSCodeColors.lightBorder,
      primaryColor: VSCodeColors.accentBlue,
      colorScheme: const ColorScheme.light(
        primary: VSCodeColors.accentBlue,
        onPrimary: Colors.white,
        secondary: VSCodeColors.accentBlue,
        onSecondary: Colors.white,
        surface: VSCodeColors.lightSidebar,
        error: VSCodeColors.accentRed,
        onSurface: VSCodeColors.lightText,
      ),
      textTheme: _buildTextTheme(
          VSCodeColors.lightText, VSCodeColors.lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor:
            const Color(0xFFDDDDDD), // Light activity bar equivalent
        foregroundColor: VSCodeColors.lightText,
        elevation: 0,
        iconTheme: const IconThemeData(color: VSCodeColors.lightText),
        titleTextStyle: _uiStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: VSCodeColors.lightText),
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
        hintStyle:
            _uiStyle(color: VSCodeColors.lightTextSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VSCodeColors.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(64, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VSCodeColors.lightText,
          side: const BorderSide(color: VSCodeColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(64, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VSCodeColors.lightText,
          textStyle: _uiStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: VSCodeColors.lightBorder),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minLeadingWidth: 20,
        horizontalTitleGap: 8,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: VSCodeColors.lightSidebar,
        surfaceTintColor: Colors.transparent,
        textStyle: _uiStyle(fontSize: 13, color: VSCodeColors.lightText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: _uiStyle(fontSize: 12, color: Colors.white),
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
        labelStyle: _uiStyle(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _uiStyle(fontSize: 13),
      ),
    );
  }

  static TextStyle _uiStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
