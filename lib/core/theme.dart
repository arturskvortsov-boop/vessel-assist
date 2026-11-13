import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette_state.dart';

// Цвета — ДИНАМИЧЕСКИЕ: читают палитру текущего раздела (PaletteState).
// Меняешь цвета разделов в palette_state.dart — перекрашивается всё.
Color get bg => PaletteState.palette.background;
Color get cardSolid => PaletteState.palette.field;
Color get border => PaletteState.palette.border;
Color get accent => PaletteState.palette.accent;
Color get accentDark => PaletteState.palette.accentDark;
Color get gold => PaletteState.palette.secondary;

// Нейтральные цвета — одинаковы во всех разделах.
const Color text = Color(0xFFF0F4F8);
const Color textMuted = Color(0xFF8B9BB4);

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
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
        // Непрозрачная подложка: фон не должен просвечивать сквозь поля ввода.
        fillColor: cardSolid,
        labelStyle: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1),
        ),
      ),
    );
  }
}
