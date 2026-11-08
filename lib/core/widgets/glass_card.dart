import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor = accent,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Пульсация туда-сюда

    _glowAnimation = Tween<double>(begin: 0.05, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Пульсирующее свечение
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Размытие фона (матовое стекло)
                child: Container(
                  decoration: BoxDecoration(
                    color: cardSolid.withValues(alpha: 0.6), // Полупрозрачный фон
                    border: Border.all(color: border.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}