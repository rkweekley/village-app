import 'package:flutter/material.dart';

class VillageTheme {
  VillageTheme._();

  // ── Brand Colors ──
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);

  // ── Kid Mode Colors ──
  static const Color kidBackground = Color(0xFFFFF8E1);
  static const Color kidPrimary = Color(0xFFFF6B6B);
  static const Color kidSecondary = Color(0xFF4ECDC4);
  static const Color kidAccent = Color(0xFFFFE66D);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryGreen,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryGreen,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get kidMode => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kidPrimary,
          brightness: Brightness.light,
          primary: kidPrimary,
          secondary: kidSecondary,
          surface: kidBackground,
        ),
        scaffoldBackgroundColor: kidBackground,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: kidPrimary,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: Colors.white,
        ),
      );
}
