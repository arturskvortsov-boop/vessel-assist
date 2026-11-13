import 'package:flutter/material.dart';

/// Раздел приложения. От раздела зависит цветовая палитра (акцент, шапка,
/// поля ввода, кнопки) и атмосферный фон.
enum AppSection {
  /// Мостик / палуба — морская палитра (голубой).
  bridge,

  /// Машинное отделение — индустриальная тёплая палитра (янтарный).
  engine,

  /// Администрирование — нейтральная палитра (серо-синий).
  admin,
}

/// Набор цветов для раздела.
///
/// Это ЕДИНСТВЕННОЕ место, где задаются цвета разделов. Меняешь здесь —
/// перекрашивается всё приложение (акценты, подложки, рамки, шапка, поля).
class SectionPalette {
  final Color accent;
  final Color accentDark;
  final Color secondary;
  final Color appBar;
  final Color field;
  final Color border;
  final Color background;

  const SectionPalette({
    required this.accent,
    required this.accentDark,
    required this.secondary,
    required this.appBar,
    required this.field,
    required this.border,
    required this.background,
  });

  /// Мостик / палуба — морская палитра (голубой).
  static const bridge = SectionPalette(
    accent: Color(0xFF38BDF8), // голубой
    accentDark: Color(0xFF0284C7),
    secondary: Color(0xFFD4AF37), // золото
    appBar: Color(0xFF0D1627),
    field: Color(0xFF0D1627),
    border: Color(0xFF1E2D48),
    background: Color(0xFF050B14),
  );

  /// Машинное отделение — янтарная индустриальная палитра.
  static const engine = SectionPalette(
    accent: Color(0xFFF59E0B), // янтарный
    accentDark: Color(0xFFB45309),
    secondary: Color(0xFFFB923C), // оранжевый
    appBar: Color(0xFF1A1206),
    field: Color(0xFF1A1206),
    border: Color(0xFF3A2E1E),
    background: Color(0xFF0A0703),
  );

  /// Администрирование — нейтральная серо-синяя палитра.
  static const admin = SectionPalette(
    accent: Color(0xFF94A3B8), // серо-синий
    accentDark: Color(0xFF475569),
    secondary: Color(0xFFCBD5E1),
    appBar: Color(0xFF0D1627),
    field: Color(0xFF0D1627),
    border: Color(0xFF2A3648),
    background: Color(0xFF050B14),
  );

  static SectionPalette of(AppSection section) {
    switch (section) {
      case AppSection.bridge:
        return bridge;
      case AppSection.engine:
        return engine;
      case AppSection.admin:
        return admin;
    }
  }
}

/// Глобальное состояние текущего раздела.
///
/// `AppScaffold` выставляет раздел при построении, а геттеры цветов в
/// `theme.dart` читают его. Так все существующие `color: accent`,
/// `color: cardSolid` и т.д. автоматически становятся цветами раздела.
class PaletteState {
  PaletteState._();

  static AppSection _section = AppSection.bridge;

  static AppSection get section => _section;

  static SectionPalette get palette => SectionPalette.of(_section);

  /// Выставляет текущий раздел. Вызывается из [AppScaffold.build] до
  /// построения детей, поэтому геттеры цветов уже вернут нужную палитру.
  static void set(AppSection section) {
    _section = section;
  }
}
