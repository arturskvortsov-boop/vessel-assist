import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Фон «Машинное отделение»: 8-битный судовой двигатель в разрезе.
///
/// Атмосфера отличается от морского [NauticalBackground]:
/// - тёплая индустриальная палитра (оранжевый/янтарный вместо синего);
/// - на фоне работает двигатель: поршни ходят вверх-вниз, коленвал
///   вращается, маховик крутится, из выхлопа идёт пар/дым;
/// - лёгкое «дыхание» свечения топки.
///
/// Всё нарисовано через [CustomPainter] — без ассетов, легко и в стиле
/// остального приложения. Анимация приглушена (низкая opacity), чтобы
/// не мешать читать данные на экранах.
class EngineRoomBackground extends StatefulWidget {
  final Widget child;
  const EngineRoomBackground({super.key, required this.child});

  @override
  State<EngineRoomBackground> createState() => _EngineRoomBackgroundState();
}

class _EngineRoomBackgroundState extends State<EngineRoomBackground>
    with TickerProviderStateMixin {
  late final AnimationController _engine; // вращение коленвала/маховика
  late final AnimationController _glow; // «дыхание» свечения

  @override
  void initState() {
    super.initState();
        _engine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _engine.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Тёплый индустриальный градиент с «дыханием» свечения.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.35),
                    radius: 1.4 + t * 0.2,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A1206),
                        const Color(0xFF2A1A08),
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

        // 2. Двигатель в разрезе (поршни, коленвал, маховик, пар).
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _engine,
            builder: (context, child) {
              return CustomPaint(
                painter: EngineCutawayPainter(_engine.value),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 3. Контент.
        widget.child,
      ],
    );
  }
}

/// Рисует 8-битный судовой двигатель в разрезе.
class EngineCutawayPainter extends CustomPainter {
  final double animationValue; // 0..1, полный оборот коленвала
  EngineCutawayPainter(this.animationValue);

  // Тёплая палитра МО.
  static const _metal = Color(0xFF3A2E1E);
  static const _metalLight = Color(0xFF5A4630);
  static const _hot = Color(0xFFF59E0B); // янтарный
  static const _flame = Color(0xFFFB923C); // оранжевый
  static const _steam = Color(0xFFE7D9C4);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Двигатель рисуем в нижней части экрана, по центру.
    final engineW = min(size.width * 0.9, 520.0);
    final engineH = engineW * 0.42;
    final left = (size.width - engineW) / 2;
    final top = size.height * 0.62;

    // --- Корпус (картер) ---
    paint.color = _metal.withValues(alpha: 0.35);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, engineW, engineH),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, paint);

    // Обводка корпуса.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _metalLight.withValues(alpha: 0.5);
    canvas.drawRRect(body, paint);
    paint.style = PaintingStyle.fill;

    // --- Цилиндры и поршни ---
    const cylinders = 4;
    final cylGap = engineW / cylinders;
    final cylW = cylGap * 0.5;
    final cylTop = top + engineH * 0.08;
    final cylH = engineH * 0.5;

    // Коленвал: центр вращения.
    final crankY = top + engineH * 0.82;
    final crankRadius = engineH * 0.16;

    for (var i = 0; i < cylinders; i++) {
      final cx = left + cylGap * (i + 0.5);

      // Гильза цилиндра.
      paint.color = _metalLight.withValues(alpha: 0.25);
      canvas.drawRect(
        Rect.fromLTWH(cx - cylW / 2, cylTop, cylW, cylH),
        paint,
      );

      // Фаза поршня: соседние цилиндры в противофазе (как у рядной четвёрки).
      final phase = animationValue * 2 * pi + (i.isEven ? 0 : pi);
      final stroke = (sin(phase) + 1) / 2; // 0..1
      final pistonY = cylTop + stroke * (cylH - cylW * 0.6);

      // Камера сгорания — вспышка в верхней точке.
      final flash = pow(max(0.0, sin(phase)), 6).toDouble();
      if (flash > 0.02) {
        paint.color = _flame.withValues(alpha: 0.35 * flash);
        canvas.drawRect(
          Rect.fromLTWH(cx - cylW / 2, cylTop, cylW, cylH * 0.18),
          paint,
        );
      }

      // Поршень.
      paint.color = _metalLight.withValues(alpha: 0.7);
      canvas.drawRect(
        Rect.fromLTWH(cx - cylW / 2 + 2, pistonY, cylW - 4, cylW * 0.6),
        paint,
      );

      // Шатун: от поршня к шейке коленвала.
      final crankAngle = phase;
      final pinX = cx + cos(crankAngle) * crankRadius * 0.5;
      final pinY = crankY + sin(crankAngle) * crankRadius * 0.5;
      paint
        ..color = _hot.withValues(alpha: 0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(cx, pistonY + cylW * 0.6),
        Offset(pinX, pinY),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }

    // --- Коленвал (вращающаяся линия) ---
    paint
      ..color = _hot.withValues(alpha: 0.45)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final crankCenter = Offset(left + engineW / 2, crankY);
    canvas.drawLine(
      Offset(
        crankCenter.dx - cos(animationValue * 2 * pi) * engineW * 0.4,
        crankY,
      ),
      Offset(
        crankCenter.dx + cos(animationValue * 2 * pi) * engineW * 0.4,
        crankY,
      ),
      paint,
    );
    paint.style = PaintingStyle.fill;

    // --- Маховик справа ---
    final flyX = left + engineW + engineH * 0.18;
    final flyR = engineH * 0.32;
    final flyCenter = Offset(flyX, crankY);
    paint
      ..color = _metalLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(flyCenter, flyR, paint);
    // Спицы маховика (вращаются).
    for (var s = 0; s < 4; s++) {
      final a = animationValue * 2 * pi + s * pi / 2;
      canvas.drawLine(
        flyCenter,
        Offset(flyCenter.dx + cos(a) * flyR, flyCenter.dy + sin(a) * flyR),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;

    // --- Пар/дым из выхлопа ---
    final steamPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      final t = (animationValue + i / 6) % 1.0;
      final sx = left + engineW * 0.15 + sin(t * pi * 2 + i) * 12;
      final sy = top - t * engineH * 0.9;
      final r = 4 + t * 10;
      steamPaint.color = _steam.withValues(alpha: (1 - t) * 0.12);
      canvas.drawCircle(Offset(sx, sy), r, steamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EngineCutawayPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
