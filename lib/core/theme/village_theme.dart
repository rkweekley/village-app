import 'package:flutter/material.dart';

class VillageTheme {
  VillageTheme._();

  // ── Brand Palette ──
  static const Color primaryTeal = Color(0xFF0D7C66);
  static const Color secondaryAmber = Color(0xFFF5A623);
  static const Color tertiaryCoral = Color(0xFFFF6B6B);
  static const Color surfaceWarm = Color(0xFFF5F0EB);
  static const Color backgroundWarm = Color(0xFFF5F0EB);

  // ── Feature Colors ──
  static const Color choresGreen = Color(0xFF2EAF7D);
  static const Color rewardsAmber = Color(0xFFF5A623);
  static const Color schoolBlue = Color(0xFF4A8FE7);
  static const Color mealsCoral = Color(0xFFFF6B6B);
  static const Color shoppingPurple = Color(0xFF8B5CF6);
  static const Color calendarCyan = Color(0xFF22D3EE);

  // ── Kid Mode ──
  static const Color kidBackground = Color(0xFFFFF8E1);
  static const Color kidPrimary = Color(0xFFFF6B6B);
  static const Color kidSecondary = Color(0xFF4ECDC4);
  static const Color kidAccent = Color(0xFFFFE66D);

  // ── Typography ──
  static const String _fontFamily = 'Inter';

  static const TextTheme _textTheme = TextTheme(
    // Display - 32px / w700
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.2,
    ),
    // Headline - 24px / w700
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    // Title - 18px / w600
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
    ),
    // Body - 15px / w400
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
    ),
    // Label - 13px / w500
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      height: 1.4,
    ),
  );

  // ── Shape Scheme ──
  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  static const ShapeBorder inputShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  static const RoundedRectangleBorder chipShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  // ── Light Theme ──
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          brightness: Brightness.light,
          primary: primaryTeal,
          secondary: secondaryAmber,
          tertiary: tertiaryCoral,
          surface: surfaceWarm,
          surfaceContainerLowest: surfaceWarm,
          surfaceContainerLow: const Color(0xFFEDE8E3),
          surfaceContainer: const Color(0xFFE5E0DB),
          surfaceContainerHigh: const Color(0xFFDED9D4),
          surfaceContainerHighest: const Color(0xFFD8D3CE),
        ),
        scaffoldBackgroundColor: backgroundWarm,
        textTheme: _textTheme,
        // ── Shape ──
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryTeal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: tertiaryCoral, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        // ── Tab Bar ──
        tabBarTheme: const TabBarThemeData(
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryTeal,
        ),
        // ── Navigation Bar ──
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: primaryTeal.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryTeal,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryTeal, size: 24);
            }
            return IconThemeData(color: Colors.grey[500], size: 24);
          }),
        ),
        // ── Buttons ──
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: buttonShape,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
        // ── Chips ──
        chipTheme: ChipThemeData(
          shape: chipShape,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        // ── Bottom Sheet ──
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        // ── Dialog ──
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          elevation: 0,
        ),
        // ── Switch ──
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primaryTeal;
            return Colors.grey[400];
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryTeal.withValues(alpha: 0.3);
            }
            return Colors.grey[200];
          }),
        ),
        // ── Divider ──
        dividerTheme: DividerThemeData(
          color: Colors.grey[200],
          thickness: 1,
          space: 1,
        ),
      );

  // ── Dark Theme ──
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          brightness: Brightness.dark,
          primary: const Color(0xFF4DD0B5),
          secondary: const Color(0xFFFFD54F),
          tertiary: const Color(0xFFFF8A80),
          surface: const Color(0xFF1A1A1A),
          surfaceContainerLowest: const Color(0xFF141414),
          surfaceContainerLow: const Color(0xFF222222),
          surfaceContainer: const Color(0xFF2A2A2A),
          surfaceContainerHigh: const Color(0xFF333333),
          surfaceContainerHighest: const Color(0xFF3D3D3D),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        textTheme: _textTheme.apply(
          bodyColor: Colors.grey[200],
          displayColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF222222),
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4DD0B5), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        // ── Tab Bar ──
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF4DD0B5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF4DD0B5),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFF222222),
          indicatorColor: const Color(0xFF4DD0B5).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4DD0B5),
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF4DD0B5), size: 24);
            }
            return IconThemeData(color: Colors.grey[500], size: 24);
          }),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      );

  // ── Kid Mode ──
  static ThemeData get kidMode => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kidPrimary,
          brightness: Brightness.light,
          primary: kidPrimary,
          secondary: kidSecondary,
          tertiary: kidAccent,
          surface: kidBackground,
        ),
        scaffoldBackgroundColor: kidBackground,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: kidPrimary,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: cardShape,
          color: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: kidSecondary.withValues(alpha: 0.2),
        ),
      );
}
