import 'package:flutter/material.dart';
import 'theme.dart';

class NauticalBackground extends StatelessWidget {
  final Widget child;
  const NauticalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Радиальный градиент (как в CSS)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [Color(0xFF0D1B2A), bg],
            ),
          ),
        ),
        // 2. Едва заметный якорь на фоне
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 0.03,
            child: Icon(
              Icons.anchor,
              size: MediaQuery.of(context).size.width * 0.9,
              color: text,
            ),
          ),
        ),
        // 3. Твой контент
        child,
      ],
    );
  }
}