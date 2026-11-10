import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _uiController;
  late Animation<double> _anchorSlide;
  late Animation<double> _textFade;

  String _displayedText = '';
  final String _fullText = 'VESSEL ASSIST';

  @override
  void initState() {
    super.initState();

    // 1. Контроллер для волн (крутится бесконечно)
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    // 2. Контроллер для интерфейса (якорь и текст)
    _uiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    // Якорь поднимается снизу вверх
    _anchorSlide = Tween<double>(begin: 200, end: 0).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeOutBack),
    );

    // Текст проявляется
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _uiController, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _uiController.forward();

    // Эффект печатной машинки
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_displayedText.length < _fullText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, _displayedText.length + 1);
        });
      } else {
        timer.cancel();
      }
    });

    // Переход на главный экран через 4 секунды
    Timer(const Duration(seconds: 4), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _uiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Анимированные волны на фоне
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: WavePainter(_waveController.value),
              );
            },
          ),

          // 2. Якорь и текст
          Center(
            child: AnimatedBuilder(
              animation: _uiController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, _anchorSlide.value),
                      child: Opacity(
                        opacity: _uiController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.anchor, size: 100, color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Text(
                            _displayedText,
                            style: const TextStyle(color: text, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DECK & ENGINE',
                            style: TextStyle(color: gold, fontSize: 12, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Художник для отрисовки волн ---
class WavePainter extends CustomPainter {
  final double animationValue;
  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height - 100 + sin((x / size.width * 4 * pi) + (animationValue * 2 * pi)) * 30;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Вторая волна (чуть выше и прозрачнее)
    paint.color = accent.withValues(alpha: 0.05);
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height - 150 + cos((x / size.width * 3 * pi) - (animationValue * 2 * pi)) * 40;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}