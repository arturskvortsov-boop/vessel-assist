import 'dart:ui';
import 'package:flutter/foundation.dart';
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

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  /// Blur (BackdropFilter) дорогой на мобильном WebKit и может смещать
  /// hit-testing. Отключаем его на вебе и на узких экранах.
  bool get _useBlur {
    if (kIsWeb) return false;
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    final inner = Container(
      decoration: BoxDecoration(
        color: cardSolid.withValues(alpha: _useBlur ? 0.6 : 0.85),
        border: Border.all(color: border.withValues(alpha: 0.5)),
        borderRadius: radius,
      ),
      child: widget.child,
    );

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
          onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.12),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _useBlur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: inner,
                    )
                  : inner,
            ),
          ),
        ),
      ),
    );
  }
}