import 'package:flutter/material.dart';

const Color navy = Color(0xFF081522);
const Color panel = Color(0xFF112437);
const Color accent = Color(0xFF4DDAC6);
const Color muted = Color(0xFF9BB0C3);
const Color outline = Color(0xFF294155);

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: navy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: muted),
      ),
    );
  }
}