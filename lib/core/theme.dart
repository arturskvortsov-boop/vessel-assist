import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Цвета из твоего CSS
const Color bg = Color(0xFF050B14);
const Color cardSolid = Color(0xFF0D1627); // Для дашборда
const Color border = Color(0xFF1E2D48);
const Color text = Color(0xFFF0F4F8);
const Color textMuted = Color(0xFF8B9BB4);
const Color accent = Color(0xFF38BDF8);
const Color accentDark = Color(0xFF0284C7);
const Color gold = Color(0xFFD4AF37);

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: gold,
        surface: cardSolid,
        onSurface: text,
      ),
      textTheme: baseTextTheme.copyWith(
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMuted),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: text, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: accent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(color: accent, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        labelStyle: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
      ),
    );
  }
}