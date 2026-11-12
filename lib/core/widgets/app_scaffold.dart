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
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: showBackground ? NauticalBackground(child: content) : content,
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
