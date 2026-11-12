import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'true_wind.dart';

enum _SpeedUnit {
  knots('kn', 1852 / 3600),
  metresPerSecond('m/s', 1);

  const _SpeedUnit(this.label, this.metresPerSecondPerUnit);
  final String label;
  final double metresPerSecondPerUnit;
}

class TrueWindScreen extends StatefulWidget {
  const TrueWindScreen({super.key});

  @override
  State<TrueWindScreen> createState() => _TrueWindScreenState();
}

class _TrueWindScreenState extends State<TrueWindScreen> {
  final _heading = TextEditingController();
  final _course = TextEditingController();
  final _shipSpeed = TextEditingController();
  final _windAngle = TextEditingController();
  final _windSpeed = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _unroundedSpeeds = <TextEditingController, double>{};
  final _scroll = ScrollController();
  _SpeedUnit _unit = _SpeedUnit.knots;
  ({Wind apparent, Wind trueWind})? _result;
  double _displayHeading = 0;
  int _revision = 0;

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final controller in [
      _heading,
      _course,
      _shipSpeed,
      _windAngle,
      _windSpeed,
    ]) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    final heading = _number(_heading.text)!;
    final result = calculateTrueWind(
      heading: heading,
      course: _number(_course.text) ?? heading,
      shipSpeed: _unroundedSpeeds[_shipSpeed] ?? _number(_shipSpeed.text)!,
      apparentSpeed: _unroundedSpeeds[_windSpeed] ?? _number(_windSpeed.text)!,
      apparentRelativeFrom: _number(_windAngle.text)!,
    );
    setState(() {
      _displayHeading = normalizeBearing(heading);
      _result = result;
      _revision++;
    });
    FocusScope.of(context).unfocus();
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _changeUnit(_SpeedUnit unit) {
    if (unit == _unit) return;
    final ratio = _unit.metresPerSecondPerUnit / unit.metresPerSecondPerUnit;
    for (final controller in [_shipSpeed, _windSpeed]) {
      final value = _unroundedSpeeds[controller] ?? _number(controller.text);
      if (value != null && value.isFinite) {
        final converted = value * ratio;
        _unroundedSpeeds[controller] = converted;
        controller.text = converted.toStringAsFixed(2);
      }
    }
    setState(() {
      _unit = unit;
      final result = _result;
      if (result != null) {
        _result = (
          apparent: (
            speed: result.apparent.speed * ratio,
            from: result.apparent.from,
          ),
          trueWind: (
            speed: result.trueWind.speed * ratio,
            from: result.trueWind.from,
          ),
        );
      }
    });
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required bool bearing,
    bool optional = false,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: bearing ? '°' : _unit.label,
        helperText: helper,
        helperMaxLines: 2,
      ),
      onChanged: (_) {
        _unroundedSpeeds.remove(controller);
        if (_result != null) setState(() => _result = null);
      },
      validator: (text) {
        final input = text ?? '';
        if (optional && input.trim().isEmpty) return null;
        final number = _number(input);
        if (number == null || !number.isFinite || number < 0) {
          return 'Enter a non-negative number.';
        }
        if (bearing && number > 360) return 'Enter an angle from 0 to 360°.';
        if (!bearing && number * _unit.metresPerSecondPerUnit > 1000) {
          return 'Speed is out of range.';
        }
        return null;
      },
    );
  }

  String _windLabel(Wind wind) {
    final from = wind.from;
    if (from == null) return 'Calm';
    final bearing = (from.round() % 360).toString().padLeft(3, '0');
    return '${wind.speed.toStringAsFixed(2)} ${_unit.label} · From $bearing° T';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final theme = Theme.of(context);
    final trueColor = theme.colorScheme.primary;
    const apparentColor = Color(0xFFFFB74D);
    return Scaffold(
      appBar: AppBar(title: const Text('True Wind Calculator')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(_revision),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, _) => CustomPaint(
                            painter: _WindDiagram(
                              heading: _displayHeading,
                              apparent: result?.apparent,
                              trueWind: result?.trueWind,
                              progress: progress,
                              knotsPerSpeedUnit:
                                  _unit.metresPerSecondPerUnit /
                                  _SpeedUnit.knots.metresPerSecondPerUnit,
                              scaleColor: theme.colorScheme.onSurfaceVariant,
                              hullColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              trueColor: trueColor,
                              apparentColor: apparentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _legend('True wind', trueColor),
                      _legend('Apparent wind', apparentColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Barbs point toward the wind source.\nShort: 5 kn · Long: 10 kn · Flag: 50 kn',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.air, color: trueColor),
                            title: const Text('True wind'),
                            subtitle: Text(_windLabel(result.trueWind)),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.air,
                              color: apparentColor,
                            ),
                            title: const Text('Apparent wind'),
                            subtitle: Text(_windLabel(result.apparent)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: SegmentedButton<_SpeedUnit>(
                      segments: [
                        for (final unit in _SpeedUnit.values)
                          ButtonSegment(value: unit, label: Text(unit.label)),
                      ],
                      selected: {_unit},
                      onSelectionChanged: (selection) =>
                          _changeUnit(selection.single),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(_heading, 'Heading (true)', bearing: true),
                  const SizedBox(height: 12),
                  _field(
                    _course,
                    'Course over ground (true)',
                    bearing: true,
                    optional: true,
                    helper: 'Leave blank to use heading as COG.',
                  ),
                  const SizedBox(height: 12),
                  _field(_shipSpeed, 'Speed over ground', bearing: false),
                  const SizedBox(height: 12),
                  _field(
                    _windAngle,
                    'Apparent wind angle from bow',
                    bearing: true,
                    helper: '0° bow · 90° starboard · 180° stern · 270° port',
                  ),
                  const SizedBox(height: 12),
                  _field(_windSpeed, 'Apparent wind speed', bearing: false),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _calculate,
                    child: const Text('Calculate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) => Chip(
    avatar: Icon(Icons.air, size: 16, color: color),
    label: Text(label),
  );
}

class _WindDiagram extends CustomPainter {
  const _WindDiagram({
    required this.heading,
    required this.apparent,
    required this.trueWind,
    required this.progress,
    required this.knotsPerSpeedUnit,
    required this.scaleColor,
    required this.hullColor,
    required this.trueColor,
    required this.apparentColor,
  });

  final double heading;
  final Wind? apparent;
  final Wind? trueWind;
  final double progress;
  final double knotsPerSpeedUnit;
  final Color scaleColor;
  final Color hullColor;
  final Color trueColor;
  final Color apparentColor;

  Offset _direction(double bearing) {
    final angle = bearing * math.pi / 180;
    return Offset(math.sin(angle), -math.cos(angle));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 25;
    final tick = Paint()
      ..color = scaleColor.withValues(alpha: .55)
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, tick..style = PaintingStyle.stroke);
    canvas.drawCircle(
      center,
      radius * .68,
      tick..color = scaleColor.withValues(alpha: .18),
    );
    tick.color = scaleColor.withValues(alpha: .55);
    for (var degrees = 0; degrees < 360; degrees += 10) {
      final direction = _direction(degrees.toDouble());
      final major = degrees % 30 == 0;
      canvas.drawLine(
        center + direction * (radius - (major ? 9 : 4)),
        center + direction * radius,
        tick,
      );
    }

    const cardinals = ['N', 'E', 'S', 'W'];
    for (final (index, label) in cardinals.indexed) {
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: scaleColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final point = center + _direction(index * 90.0) * (radius + 13);
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }

    final apparentFrom = apparent?.from;
    final trueFrom = trueWind?.from;
    final overlap =
        apparentFrom != null &&
        trueFrom != null &&
        ((apparentFrom - trueFrom + 180) % 360 - 180).abs() < 12;
    _drawBarb(
      canvas,
      center,
      radius,
      apparent,
      apparentColor,
      separation: overlap ? -8 : 0,
      featherSide: -1,
      calmRadius: 32,
    );
    _drawBarb(
      canvas,
      center,
      radius,
      trueWind,
      trueColor,
      separation: overlap ? 8 : 0,
      featherSide: overlap ? 1 : -1,
      calmRadius: 39,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(((heading + 180) % 360 - 180) * progress * math.pi / 180);
    final hull = Path()
      ..moveTo(0, -27)
      ..quadraticBezierTo(11, -17, 12, -5)
      ..lineTo(12, 19)
      ..quadraticBezierTo(12, 24, 7, 24)
      ..lineTo(-7, 24)
      ..quadraticBezierTo(-12, 24, -12, 19)
      ..lineTo(-12, -5)
      ..quadraticBezierTo(-11, -17, 0, -27)
      ..close();
    canvas.drawPath(hull, Paint()..color = hullColor);
    canvas.drawPath(
      hull,
      Paint()
        ..color = scaleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, 5, 14, 11),
        const Radius.circular(2),
      ),
      Paint()..color = scaleColor.withValues(alpha: .5),
    );
    canvas.restore();
  }

  void _drawBarb(
    Canvas canvas,
    Offset center,
    double radius,
    Wind? wind,
    Color color, {
    required double separation,
    required double featherSide,
    required double calmRadius,
  }) {
    if (wind == null || progress == 0) return;
    final steps = (wind.speed * knotsPerSpeedUnit / 5 + 1e-9).round();
    final from = wind.from;
    final stroke = Paint()
      ..color = color.withValues(alpha: progress)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (from == null || steps == 0) {
      canvas.drawCircle(
        center,
        calmRadius,
        stroke..style = PaintingStyle.stroke,
      );
      return;
    }

    final source = _direction(from);
    final side = Offset(-source.dy, source.dx);
    final origin = center + side * separation;
    final start = origin + source * 34;
    final staffLength = math.max(0.0, radius - 48);
    final end = start + source * staffLength;
    canvas.drawLine(start, start + source * (staffLength * progress), stroke);

    final flags = steps ~/ 10;
    final full = (steps % 10) ~/ 2;
    final half = steps.isOdd;
    final spacing = math.min(8.0, staffLength / (flags * 1.5 + full + 3));
    final feather = side * (22 * featherSide);
    var inset = 0.0;
    for (var i = 0; i < flags; i++) {
      final outer = end - source * inset;
      final inner = outer - source * (spacing * 1.5);
      canvas.drawPath(
        Path()
          ..moveTo(outer.dx, outer.dy)
          ..lineTo((outer + feather).dx, (outer + feather).dy)
          ..lineTo(inner.dx, inner.dy)
          ..close(),
        stroke,
      );
      inset += spacing * 1.5;
    }
    for (var i = 0; i < full; i++) {
      final root = end - source * inset;
      canvas.drawLine(root, root + feather - source * (spacing * .55), stroke);
      inset += spacing;
    }
    if (half) {
      if (flags == 0 && full == 0) inset += spacing;
      final root = end - source * inset;
      canvas.drawLine(
        root,
        root + feather * .5 - source * (spacing * .3),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindDiagram oldDelegate) =>
      heading != oldDelegate.heading ||
      apparent != oldDelegate.apparent ||
      trueWind != oldDelegate.trueWind ||
      progress != oldDelegate.progress ||
      knotsPerSpeedUnit != oldDelegate.knotsPerSpeedUnit ||
      scaleColor != oldDelegate.scaleColor ||
      hullColor != oldDelegate.hullColor ||
      trueColor != oldDelegate.trueColor ||
      apparentColor != oldDelegate.apparentColor;
}
