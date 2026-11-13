import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette_state.dart';
import 'theme.dart';

export 'palette_state.dart' show AppSection, SectionPalette;

/// Даёт доступ к палитре текущего раздела из любого виджета-потомка.
class SectionTheme extends InheritedWidget {
  final AppSection section;
  final SectionPalette palette;

  const SectionTheme({
    super.key,
    required this.section,
    required this.palette,
    required super.child,
  });

  static SectionTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SectionTheme>();

  static SectionPalette of(BuildContext context) =>
      maybeOf(context)?.palette ?? SectionPalette.bridge;

  static AppSection sectionOf(BuildContext context) =>
      maybeOf(context)?.section ?? AppSection.bridge;

  @override
  bool updateShouldNotify(SectionTheme oldWidget) =>
      oldWidget.section != section || oldWidget.palette != palette;
}

/// Собирает [ThemeData] под конкретный раздел.
class SectionThemeData {
  static final Map<AppSection, ThemeData> _cache = {};

  static ThemeData build(AppSection section) {
    return _cache.putIfAbsent(section, () => _build(section));
  }

  static ThemeData _build(AppSection section) {
    final palette = SectionPalette.of(section);
    final darkBase = ThemeData.dark().textTheme;

    TextTheme baseTextTheme;
    TextStyle? appBarTitle;
    if (GoogleFonts.config.allowRuntimeFetching) {
      baseTextTheme = GoogleFonts.interTextTheme(darkBase);
      appBarTitle = GoogleFonts.inter(
        color: palette.accent,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );
    } else {
      baseTextTheme = darkBase;
      appBarTitle = TextStyle(
        color: palette.accent,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: palette.accent,
        secondary: palette.secondary,
        surface: palette.field,
        onSurface: text,
      ),
      textTheme: baseTextTheme.copyWith(
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMuted),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.appBar,
        foregroundColor: palette.accent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appBarTitle,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.accent,
        unselectedLabelColor: textMuted,
        indicatorColor: palette.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        labelStyle: const TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.background,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.background,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.field,
        foregroundColor: palette.accent,
      ),
    );
  }
}
