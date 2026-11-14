import 'package:flutter/material.dart';
import 'palette_state.dart';

/// Нейтральный фон для раздела «Администрирование».
///
/// Спокойный статичный градиент без анимации — раздел про документы,
/// инструменты и настройки, атмосферные эффекты здесь не нужны.
class NeutralBackground extends StatelessWidget {
  final Widget child;
  const NeutralBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = PaletteState.palette;
    return Stack(
      children: [
        // Мягкий радиальный градиент от нейтрального центра к фону раздела.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.3,
                colors: [
                  Color.lerp(palette.background, palette.field, 0.6)!,
                  palette.background,
                ],
              ),
            ),
          ),
        ),
        // Едва заметная сетка-«миллиметровка» для «инженерного» вида.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GridPainter(palette.border.withValues(alpha: 0.25)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
