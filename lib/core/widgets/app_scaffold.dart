import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nautical_background.dart';
import '../theme.dart';

/// Единый каркас экрана в стиле приложения.
///
/// Даёт:
/// - фон NauticalBackground (анимированный, но лёгкий);
/// - единый AppBar с кнопкой "назад";
/// - центрирование контента по ширине (maxWidth) для планшетов/десктопа.
///
/// Использование:
/// ```dart
/// AppScaffold(
///   title: 'ETA Calculator',
///   body: ListView(...),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackground;
  final double maxWidth;
  final bool centerContent;

  /// Показывать плавающую кнопку "Домой" (якорь) в правом нижнем углу.
  /// По умолчанию включена на всех внутренних экранах.
  final bool showHomeFab;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackground = true,
    this.maxWidth = 900,
    this.centerContent = true,
    this.showHomeFab = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = centerContent
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          )
        : body;

    // Если экран передал свой FAB — показываем его, иначе (при showHomeFab)
    // показываем кнопку "Домой" в виде якоря.
    final fab = floatingActionButton ??
        (showHomeFab ? const _HomeAnchorFab() : null);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottomNavigationBar,
      body: showBackground ? NauticalBackground(child: content) : content,
    );
  }
}

/// Плавающая кнопка "Домой" в стиле якоря.
/// Ведёт на главный экран. Располагается справа снизу (под правый палец),
/// автоматически поднимается над нижней навигацией и учитывает SafeArea.
class _HomeAnchorFab extends StatelessWidget {
  const _HomeAnchorFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'home_anchor_fab',
      backgroundColor: cardSolid,
      foregroundColor: accent,
      elevation: 6,
      tooltip: 'Home',
      shape: const CircleBorder(side: BorderSide(color: border)),
      onPressed: () => context.go('/'),
      child: const Icon(Icons.anchor),
    );
  }
}

/// Единая карточка-секция в стиле приложения.
/// Заменяет локальные `_card(...)` контейнеры на экранах.
class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color borderColor;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor = border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
