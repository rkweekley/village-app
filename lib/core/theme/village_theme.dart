import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Taste-applied Village theme. Single accent palette, Outfit typeface,
/// warm surfaces, refined spacing.
class VillageTheme {
  VillageTheme._();

  // ── Single Accent Palette ──
  // Teal is the ONE accent. Every other color derives from it or neutrals.
  static const Color primary = Color(0xFF0D7C66);
  static const Color primaryLight = Color(0xFF3DA58D);
  static const Color primaryDark = Color(0xFF095F4E);
  static const Color onPrimary = Colors.white;

  // Surfaces — warm off-white, never pure #FFF
  static const Color surfaceBase = Color(0xFFF5F0EB);
  static const Color surfaceCard = Color(0xFFFBF8F5);
  static const Color surfaceElevated = Colors.white;

  // Neutrals — single gray family (warm-tinted)
  static const Color textPrimary = Color(0xFF1E1B18);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color textTertiary = Color(0xFF9E9893);
  static const Color borderSubtle = Color(0xFFE8E3DE);

  // Semantic (derived from primary — desaturated)
  static const Color positive = Color(0xFF2EAF7D);
  static const Color warning = Color(0xFFD4950A);
  static const Color danger = Color(0xFFDC5C4A);
  static const Color info = Color(0xFF4A8FE7);

  // ── Typography: Outfit ──
  static TextTheme textTheme = GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.15,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.25,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleSmall: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
    ),
    bodyLarge: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      height: 1.4,
    ),
    labelMedium: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      height: 1.4,
    ),
    labelSmall: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      height: 1.4,
    ),
  );

  // ── Shape System (varied radius — tighter inner, softer outer) ──
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // ── Spacing Tokens ──
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // ── Light Theme ──
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: const Color(0xFFC8EDE3),
          secondary: primaryLight,
          surface: surfaceBase,
          surfaceContainerLowest: surfaceBase,
          surfaceContainerLow: const Color(0xFFEDE8E3),
          surfaceContainer: const Color(0xFFE5E0DB),
          surfaceContainerHigh: const Color(0xFFDED9D4),
          surfaceContainerHighest: const Color(0xFFD8D3CE),
          error: danger,
        ),
        scaffoldBackgroundColor: surfaceBase,
        textTheme: textTheme,

        // ── Cards (elevation 0, colored surface, no generic border+shadow) ──
        cardTheme: CardThemeData(
          elevation: 0,
          color: surfaceCard,
          shadowColor: primary.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: borderSubtle, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 10),
        ),

        // ── Inputs (subtle fills, no harsh borders) ──
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: danger, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        ),

        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: surfaceBase,
          foregroundColor: textPrimary,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
        ),

        tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textTertiary,
          indicatorColor: primary,
          labelStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ── Navigation Bar (desktop web: subtle) ──
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: surfaceCard,
          indicatorColor: primary.withValues(alpha: 0.10),
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              );
            }
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textTertiary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return IconThemeData(color: textTertiary, size: 22);
          }),
        ),

        // ── Buttons ──
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            side: const BorderSide(color: borderSubtle),
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Chips ──
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          backgroundColor: surfaceCard,
          side: const BorderSide(color: borderSubtle),
          labelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
          ),
        ),

        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusXl)),
          ),
          elevation: 0,
          backgroundColor: surfaceCard,
        ),

        // ── Divider ──
        dividerTheme: const DividerThemeData(
          color: borderSubtle,
          thickness: 1,
          space: 1,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      );

  // ── Dark Theme ──
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: const Color(0xFF4DD0B5),
          onPrimary: const Color(0xFF0A2E25),
          secondary: const Color(0xFF80DEC9),
          surface: const Color(0xFF141210),
          surfaceContainerLowest: const Color(0xFF0E0C0A),
          surfaceContainerLow: const Color(0xFF1C1A17),
          surfaceContainer: const Color(0xFF242220),
          surfaceContainerHigh: const Color(0xFF2C2A27),
          surfaceContainerHighest: const Color(0xFF343230),
          error: const Color(0xFFFF8A80),
        ),
        scaffoldBackgroundColor: const Color(0xFF141210),
        textTheme: textTheme.apply(
          bodyColor: const Color(0xFFDDD8D3),
          displayColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1C1A17),
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 10),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF141210),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242220),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: Color(0xFF4DD0B5), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          labelStyle: GoogleFonts.outfit(
            color: const Color(0xFF9E9893),
            fontWeight: FontWeight.w500,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFF1C1A17),
          height: 64,
          indicatorColor: const Color(0xFF4DD0B5).withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4DD0B5),
              );
            }
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9E9893),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF4DD0B5), size: 22);
            }
            return const IconThemeData(color: Color(0xFF9E9893), size: 22);
          }),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusXl)),
          ),
          backgroundColor: const Color(0xFF1C1A17),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      );
}
