import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final int decimals;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 1,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text('${val.toStringAsFixed(decimals)}$suffix', style: style);
      },
    );
  }
}