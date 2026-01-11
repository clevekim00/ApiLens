
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/app_tokens.dart';

class AppThemeDark {
  static ThemeData get themeData {
    final baseTextTheme = AppTokens.textTheme.apply(
      bodyColor: AppColorsDark.foreground,
      displayColor: AppColorsDark.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark.background,
      primaryColor: AppColorsDark.primary,
      canvasColor: AppColorsDark.background,
      cardColor: AppColorsDark.card,
      dividerColor: AppColorsDark.border,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.primaryForeground,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.secondaryForeground,
        surface: AppColorsDark.card,
        onSurface: AppColorsDark.cardForeground,
        error: AppColorsDark.destructive,
        onError: AppColorsDark.destructiveForeground,
        outline: AppColorsDark.border,
        // Custom extensions or misuse of slots for shadcn mapping
        // 'surfaceContainer' (Flutter 3.22+) or similar could be used but let's stick to basics
      ),

      textTheme: baseTextTheme,

      dividerTheme: const DividerThemeData(
        color: AppColorsDark.border,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.input,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: AppColorsDark.mutedForeground),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsDark.ring, width: 1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColorsDark.destructive, width: 1),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColorsDark.foreground,
        unselectedLabelColor: AppColorsDark.mutedForeground,
        indicatorColor: AppColorsDark.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColorsDark.border,
        labelStyle: AppTokens.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTokens.textTheme.bodyMedium,
        // Underline style is default indicator for TabBar, but we can customize if needed
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.popover,
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(AppTokens.radiusMd),
           side: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        titleTextStyle: baseTextTheme.titleLarge,
        contentTextStyle: baseTextTheme.bodyMedium,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsDark.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        textStyle: baseTextTheme.bodyMedium,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: MaterialStateProperty.all(true),
        thickness: MaterialStateProperty.all(8),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return AppColorsDark.mutedForeground;
          }
          return AppColorsDark.mutedForeground.withOpacity(0.5);
        }),
      ),
      
      // Additional Button Themes to match Shadcn
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.primaryForeground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.foreground,
          side: const BorderSide(color: AppColorsDark.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          textStyle: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
        ),
      ),
    );
  }
}
