import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class NauticalBackground extends StatefulWidget {
  final Widget child;
  const NauticalBackground({super.key, required this.child});

  @override
  State<NauticalBackground> createState() => _NauticalBackgroundState();
}

class _NauticalBackgroundState extends State<NauticalBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    // Медленное "дыхание" свечения фона
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    
    
    for (int i = 0; i < 10; i++) { // Было 30, стало 10 для веба
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        speedInt: _random.nextInt(3) + 1, // Скорость 1, 2 или 3
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

    @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
                // 1. Радиальный градиент с плавным "дыханием" свечения
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_glowController.value);
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.5 + t * 0.25,
                            colors: [
                              Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF122A44), t)!,
                              bg,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        
                // 2. Частицы (Пыль/Пузырьки)
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 3. Плывущий 8-битный корабль
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: PixelShipPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),

                // 4. Едва заметный якорь с лёгким параллаксом
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_glowController.value);
                      return Positioned(
                        top: 60 + t * 8,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 0.03 + t * 0.015,
                          child: Icon(
                            Icons.anchor,
                            size: MediaQuery.of(context).size.width * 0.9,
                            color: text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        
        // 5. Контент
        widget.child,
      ],
    );
  }
}

class Particle {
  double x, y;
  final double size, opacity;
  final int speedInt; // Целое число для идеального зацикливания
  Particle({required this.x, required this.y, required this.size, required this.speedInt, required this.opacity});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      final currentY = (p.y - (animationValue * p.speedInt)) % 1.0;
      final sway = sin(animationValue * pi * 2 + p.y * 10) * 0.02;
      final currentX = (p.x + sway) % 1.0;
      paint.color = accent.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(currentX * size.width, currentY * size.height), p.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- Художник для 8-битного корабля и волн ---
class PixelShipPainter extends CustomPainter {
  final double animationValue;
  PixelShipPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.7; // Базовая высота
    final shipColor = text.withValues(alpha: 0.15); 
    final windowColor = accent.withValues(alpha: 0.3);
    final waveColor = accent.withValues(alpha: 0.05); // Цвет волн

    // 1. Рисуем пиксельные волны на фоне (сзади корабля)
    final wavePaint = Paint()..color = waveColor..style = PaintingStyle.fill;
    for (double i = 0; i < size.width; i += 20) {
      // Волны двигаются синусоидой
      final waveY = baseY + 35 + sin(i / 40 + animationValue * pi * 4) * 8;
      canvas.drawRect(Rect.fromLTWH(i, waveY, 20, 10), wavePaint);
    }

    // 2. Рассчитываем качку корабля
    final totalWidth = size.width + 300;
    final x = (totalWidth * animationValue) - 150;
    // Корабль поднимается и опускается (Y)
    final y = baseY + sin(animationValue * pi * 16) * 10; 
    // Корабль наклоняется (угол)
    final angle = cos(animationValue * pi * 16) * 0.05; 

    // Сохраняем состояние холста для наклона
    canvas.save();
    // Вращаем холст вокруг центра корабля (x + 40, y + 15)
    canvas.translate(x + 40, y + 15);
    canvas.rotate(angle);
    canvas.translate(-(x + 40), -(y + 15));

    final paint = Paint()..style = PaintingStyle.fill;

    // --- Рисуем корабль ---
    paint.color = shipColor;
    canvas.drawRect(Rect.fromLTWH(x, y, 80, 20), paint); // Основная палуба
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 20, 60, 10), paint); // Низ
    canvas.drawRect(Rect.fromLTWH(x + 70, y - 10, 10, 30), paint); // Нос

    // Надстройка
    canvas.drawRect(Rect.fromLTWH(x + 20, y - 20, 30, 20), paint);
    
    // Труба
    canvas.drawRect(Rect.fromLTWH(x + 35, y - 40, 10, 20), paint);

    // Иллюминаторы
    paint.color = windowColor;
    canvas.drawRect(Rect.fromLTWH(x + 25, y - 15, 4, 4), paint);
    canvas.drawRect(Rect.fromLTWH(x + 35, y - 15, 4, 4), paint);
    canvas.drawRect(Rect.fromLTWH(x + 45, y - 15, 4, 4), paint);

    // Дым
    paint.color = shipColor;
    final smokeOffset = sin(animationValue * pi * 10) * 3;
    canvas.drawRect(Rect.fromLTWH(x + 37 + smokeOffset, y - 50, 6, 6), paint);
    canvas.drawRect(Rect.fromLTWH(x + 40 + smokeOffset, y - 60, 8, 8), paint);
    
    // Восстанавливаем холст (убираем наклон)
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}