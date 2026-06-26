import 'package:flutter/material.dart';

class LumoraColors {
  static const ivory = Color(0xFFFAF6EE);
  static const champagne = Color(0xFFC9A86A);
  static const ink = Color(0xFF2B2723);
  static const muted = Color(0xFF7A6F62);
  static const surface = Color(0xFFFFFCF7);
  static const border = Color(0xFFE8DDCF);
}

class LumoraSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class LumoraTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LumoraColors.champagne,
      brightness: Brightness.light,
      surface: LumoraColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        primary: LumoraColors.champagne,
        onPrimary: LumoraColors.ink,
        surface: LumoraColors.surface,
        onSurface: LumoraColors.ink,
      ),
      scaffoldBackgroundColor: LumoraColors.ivory,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: LumoraColors.ink,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        bodyLarge: TextStyle(
          color: LumoraColors.muted,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: LumoraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: LumoraColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LumoraColors.ink,
          foregroundColor: LumoraColors.surface,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
