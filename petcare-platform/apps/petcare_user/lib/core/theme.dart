import 'package:flutter/material.dart';

class PetColors {
  // Primary brand palette - deep charcoal / near-black
  static const Color primary = Color(0xFF1A1F1D);
  static const Color primaryDark = Color(0xFF0F1211);
  static const Color primaryLight = Color(0xFFEBECE9);

  // Secondary & Accents - muted sage green & restrained warm coral
  static const Color sage = Color(0xFF3E5C4E);
  static const Color sageLight = Color(0xFFEDF3F0);
  static const Color coral = Color(0xFFD96650);
  static const Color coralLight = Color(0xFFFBECE8);
  static const Color accent = Color(0xFFD96650);
  static const Color amber = Color(0xFFC67D19);
  static const Color amberLight = Color(0xFFFBF4E9);
  static const Color sky = Color(0xFF367399);
  static const Color skyLight = Color(0xFFEDF4F8);

  // Neutrals - warm organic tones
  static const Color dark = Color(0xFF1A1F1D);
  static const Color darkMuted = Color(0xFF57605A);
  static const Color darkLight = Color(0xFF8B948E);
  static const Color border = Color(0xFFE8E9E4);
  static const Color borderSubtle = Color(0xFFF2F3EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF9F6);

  // Semantic
  static const Color success = Color(0xFF2E7D52);
  static const Color successBg = Color(0xFFEDF6F1);
  static const Color error = Color(0xFFC84B46);
  static const Color errorBg = Color(0xFFFDF0EF);
  static const Color warning = Color(0xFFC67D19);
  static const Color warningBg = Color(0xFFFBF4E9);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);
}

class PetTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: PetColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PetColors.dark,
        primary: PetColors.primary,
        onPrimary: Colors.white,
        secondary: PetColors.sage,
        surface: PetColors.surface,
        background: PetColors.background,
        error: PetColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: PetColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: PetColors.dark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: PetColors.dark),
      ),
      cardTheme: CardThemeData(
        color: PetColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: PetColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PetColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PetColors.dark,
          side: const BorderSide(color: PetColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PetColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PetColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PetColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PetColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: PetColors.darkLight,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: PetColors.darkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: PetColors.primary,
        unselectedItemColor: PetColors.darkLight,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: PetColors.border,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
