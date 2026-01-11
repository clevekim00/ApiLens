
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/app_tokens.dart';

class AppThemeLight {
  static ThemeData get themeData {
    final baseTextTheme = AppTokens.textTheme.apply(
      bodyColor: AppColorsLight.foreground,
      displayColor: AppColorsLight.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.background,
      primaryColor: AppColorsLight.primary,
      canvasColor: AppColorsLight.background,
      cardColor: AppColorsLight.card,
      dividerColor: AppColorsLight.border,
      
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.primary,
        onPrimary: AppColorsLight.primaryForeground,
        secondary: AppColorsLight.secondary,
        onSecondary: AppColorsLight.secondaryForeground,
        surface: AppColorsLight.card,
        onSurface: AppColorsLight.cardForeground,
        error: AppColorsLight.destructive,
        onError: AppColorsLight.destructiveForeground,
        outline: AppColorsLight.border,
      ),

      textTheme: baseTextTheme,

      dividerTheme: const DividerThemeData(
        color: AppColorsLight.border,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.input,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: AppColorsLight.mutedForeground),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsLight.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsLight.ring, width: 1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsLight.border, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsLight.destructive, width: 1),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColorsLight.foreground,
        unselectedLabelColor: AppColorsLight.mutedForeground,
        indicatorColor: AppColorsLight.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColorsLight.border,
        labelStyle: AppTokens.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTokens.textTheme.bodyMedium,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.popover,
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(AppTokens.radiusMd),
           side: const BorderSide(color: AppColorsLight.border, width: 1),
        ),
        titleTextStyle: baseTextTheme.titleLarge,
        contentTextStyle: baseTextTheme.bodyMedium,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsLight.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: const BorderSide(color: AppColorsLight.border, width: 1),
        ),
        textStyle: baseTextTheme.bodyMedium,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: MaterialStateProperty.all(true),
        thickness: MaterialStateProperty.all(8),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return AppColorsLight.mutedForeground;
          }
          return AppColorsLight.mutedForeground.withOpacity(0.5);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: AppColorsLight.primaryForeground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.foreground,
          side: const BorderSide(color: AppColorsLight.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),
    );
  }
}
