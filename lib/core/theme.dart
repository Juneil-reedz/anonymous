import 'package:flutter/material.dart';

class AnonTheme {
  // ── Core palette ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF1F150C);
  static const Color card = Color(0xFF412D15);
  static const Color cardBorder = Color(0xFF5C3E22);
  static const Color primary = Color(0xFFE1DCC9);      // cream — main accent
  static const Color primaryLight = Color(0xFFC9A87C); // warm amber — highlights
  static const Color subtext = Color(0xFF8B7355);      // warm muted

  // ── Semantic aliases ─────────────────────────────────────────────────────────
  static const Color cream = primary;
  static const Color amber = primaryLight;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: primary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: primary),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: primary, fontWeight: FontWeight.w900),
          displayMedium:
              TextStyle(color: primary, fontWeight: FontWeight.w900),
          headlineLarge:
              TextStyle(color: primary, fontWeight: FontWeight.w800),
          headlineMedium:
              TextStyle(color: primary, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: primary),
          bodyMedium: TextStyle(color: subtext),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: card),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: card),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          hintStyle: const TextStyle(color: subtext),
          labelStyle: const TextStyle(color: subtext),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryLight),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: card,
          contentTextStyle: const TextStyle(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.black,
        ),
        dividerColor: cardBorder,
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: primary),
        popupMenuTheme: PopupMenuThemeData(
          color: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}
