import 'package:flutter/material.dart';

class DraftMarksDiagram extends StatelessWidget {
  const DraftMarksDiagram({
    super.key,
    required this.starboard,
    required this.selectedStation,
    required this.trimByStern,
    required this.onSelect,
  });

  final bool starboard;
  final int? selectedStation;
  final double? trimByStern;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const stations = ['FWD', 'MID', 'AFT'];
    final angle = ((trimByStern ?? 0) * 0.05).clamp(-0.16, 0.16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: colors.surface,
            child: SizedBox(
              height: 114,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: angle),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                builder: (context, value, child) => CustomPaint(
                  painter: _HullPainter(
                    angle: value,
                    starboard: starboard,
                    station: selectedStation,
                    accent: colors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final index in starboard ? [2, 1, 0] : [0, 1, 2])
              Expanded(
                child: TextButton(
                  onPressed: () => onSelect(index),
                  child: Text(stations[index]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HullPainter extends CustomPainter {
  const _HullPainter({
    required this.angle,
    required this.starboard,
    required this.station,
    required this.accent,
  });

  final double angle;
  final bool starboard;
  final int? station;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 320, size.height / 114);
    canvas.drawRect(
      const Rect.fromLTWH(0, 66, 320, 48),
      Paint()..color = const Color(0xFF102D46),
    );
    canvas.save();
    if (starboard) {
      canvas.translate(320, 0);
      canvas.scale(-1, 1);
    }
    canvas.translate(160, 62);
    canvas.rotate(angle);
    canvas.translate(-160, -62);
    final hull = Path()
      ..moveTo(20, 49)
      ..lineTo(48, 56)
      ..lineTo(239, 56)
      ..lineTo(239, 39)
      ..lineTo(258, 39)
      ..lineTo(258, 28)
      ..lineTo(268, 28)
      ..lineTo(268, 39)
      ..lineTo(281, 39)
      ..lineTo(281, 55)
      ..lineTo(301, 55)
      ..quadraticBezierTo(295, 83, 273, 86)
      ..lineTo(60, 86)
      ..quadraticBezierTo(30, 84, 20, 49)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF34526C));
    canvas.drawPath(
      hull,
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke,
    );
    const marks = [54.0, 160.0, 267.0];
    for (var i = 0; i < marks.length; i++) {
      final x = marks[i];
      final paint = Paint()
        ..color = i == station ? accent : const Color(0xFFA8BBCD);
      paint.strokeWidth = i == station ? 2 : 1;
      for (var y = 59.0; y <= 79; y += 5) {
        canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), paint);
      }
    }
    canvas.restore();
    canvas.drawLine(
      const Offset(0, 66),
      const Offset(320, 66),
      Paint()..color = accent.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _HullPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.starboard != starboard ||
      oldDelegate.station != station ||
      oldDelegate.accent != accent;
}
