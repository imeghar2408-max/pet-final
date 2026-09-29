import 'package:flutter/material.dart';

class ProviderTheme {
  static const Color sagePrimary = Color(0xFF2D5A27);
  static const Color sageLight = Color(0xFFE8EFE9);
  static const Color sageBorder = Color(0xFFB7D3B5);

  static const Color coralAccent = Color(0xFFD9534F);
  static const Color coralLight = Color(0xFFFDF0EF);
  static const Color coralBorder = Color(0xFFF5C2C0);

  static const Color background = Color(0xFFF9FBF9);
  static const Color surfaceMuted = Color(0xFFF0F4F1);
  static const Color border = Color(0xFFE2E8E2);

  static const Color charcoal = Color(0xFF1E2923);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: sagePrimary,
        secondary: coralAccent,
        surface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: sagePrimary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData themeData() => lightTheme;
}
