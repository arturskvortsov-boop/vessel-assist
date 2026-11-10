import 'package:flutter/material.dart';

class StaggeredItem extends StatelessWidget {
  final Widget child;
  final int index;

  const StaggeredItem({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Каждая следующая карточка появляется чуть медленнее (эффект волны)
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - val)), // Всплывает снизу
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}