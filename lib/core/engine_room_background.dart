import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Фон «Машинное отделение».
///
/// Спокойная стальная палитра (глубокий сине-серый) с мягким пульсирующим
/// свечением и медленно плывущими тонкими линиями-«потоками». Анимация
/// ненавязчивая, чтобы не отвлекать от данных на экранах.
class EngineRoomBackground extends StatefulWidget {
  final Widget child;
  const EngineRoomBackground({super.key, required this.child});

  @override
  State<EngineRoomBackground> createState() => _EngineRoomBackgroundState();
}

class _EngineRoomBackgroundState extends State<EngineRoomBackground>
    with TickerProviderStateMixin {
  late final AnimationController _flow; // медленное движение линий
  late final AnimationController _glow; // «дыхание» свечения

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flow.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Спокойный стальной градиент с мягким «дыханием» свечения.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.5 + t * 0.15,
                    colors: [
                      Color.lerp(
                        const Color(0xFF16202B),
                        const Color(0xFF1B2836),
                        t,
                      )!,
                      bg,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 2. Медленно плывущие тонкие линии-«потоки».
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _flow,
            builder: (context, child) {
              return CustomPaint(
                painter: _FlowLinesPainter(_flow.value),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 3. Контент. Positioned.fill даёт child ограниченную высоту,
        // иначе ListView внутри Stack (loose) не скроллится.
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// Рисует набор тонких плавно изгибающихся линий, медленно дрейфующих
/// по экрану. Просто, но создаёт ощущение живого, спокойного фона.
class _FlowLinesPainter extends CustomPainter {
  final double t; // 0..1
  _FlowLinesPainter(this.t);

  static const _line = Color(0xFF4A6B85);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const lineCount = 7;
    final phase = t * 2 * pi;

    for (var i = 0; i < lineCount; i++) {
      final baseY = size.height * (0.12 + i * 0.12);
      final amp = 18.0 + i * 4;
      final speed = 0.6 + i * 0.12;
      final alpha = 0.05 + (i % 3) * 0.02;

      paint.color = _line.withValues(alpha: alpha);

      final path = Path();
      const steps = 40;
      for (var s = 0; s <= steps; s++) {
        final x = size.width * s / steps;
        final y = baseY +
            sin(phase * speed + s / steps * 2 * pi + i) * amp +
            cos(phase * 0.5 + i) * 6;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Мягкое свечение в верхней части — «дыхание».
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 0.9,
        colors: [
          _line.withValues(alpha: 0.06 + 0.03 * sin(phase)),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowLinesPainter oldDelegate) =>
      oldDelegate.t != t;
}
