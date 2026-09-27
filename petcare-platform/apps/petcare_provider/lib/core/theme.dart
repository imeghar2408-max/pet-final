import 'package:flutter/material.dart';

class ProviderTheme {
  // Palette: warm neutral background, deep charcoal text, muted sage green accents, muted coral CTAs
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF3F1EC);
  static const Color charcoal = Color(0xFF1A1F1D);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E2DA);
  
  static const Color sagePrimary = Color(0xFF2E6B56);
  static const Color sageLight = Color(0xFFEBF3EF);
  static const Color sageBorder = Color(0xFFC7DDD4);
  
  static const Color coralAccent = Color(0xFFD9534F);
  static const Color coralLight = Color(0xFFFDF0ED);
  static const Color coralBorder = Color(0xFFF8CCC4);

  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: sagePrimary,
        onPrimary: Colors.white,
        secondary: charcoal,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: charcoal,
        error: coralAccent,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: charcoal),
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sagePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: sagePrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: sageLight,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: sagePrimary, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: sagePrimary, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
    );
  }
}
