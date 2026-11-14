import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'sea_routes.dart';

List<List<List<SeaPoint>>> readLand(String source) {
  return [
    for (final feature in jsonDecode(source)['features'] as List)
      for (final polygon in _polygons(feature['geometry']))
        [
          for (final ring in polygon as List)
            [
              for (final coordinate in ring as List)
                readPoint(coordinate as List),
            ],
        ],
  ];
}

List _polygons(Map<String, dynamic> geometry) => geometry['type'] == 'Polygon'
    ? [geometry['coordinates']]
    : geometry['coordinates'] as List;

class RouteMap extends StatefulWidget {
  final SeaRoute route;
  final List<List<List<SeaPoint>>> land;
  final String departureCode;
  final String arrivalCode;

  /// Текущая позиция судна (GPS), если доступна.
  final SeaPoint? myPosition;

  const RouteMap({
    super.key,
    required this.route,
    required this.land,
    required this.departureCode,
    required this.arrivalCode,
    this.myPosition,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  // Состояние жеста.
  double _startZoom = 1.0;
  Offset _startPan = Offset.zero;
  Offset _startFocal = Offset.zero;

  static const _minZoom = 1.0;
  static const _maxZoom = 8.0;

  void _onScaleStart(ScaleStartDetails d) {
    _startZoom = _zoom;
    _startPan = _pan;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final newZoom = (_startZoom * d.scale).clamp(_minZoom, _maxZoom);
    // Панорамирование: сдвиг пальца + компенсация зума вокруг фокальной точки.
    final focal = d.localFocalPoint;
    final zoomFactor = newZoom / _startZoom;
    final newPan = _startPan + (focal - _startFocal) +
        (_startFocal - _startPan) * (1 - zoomFactor);
    setState(() {
      _zoom = newZoom;
      _pan = newPan;
    });
  }

  void _reset() => setState(() {
        _zoom = 1.0;
        _pan = Offset.zero;
      });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        image: true,
        label: 'Approximate sea route from ${widget.departureCode} to ${widget.arrivalCode}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: CustomPaint(
                      painter: _RoutePainter(
                        widget.route,
                        widget.land,
                        widget.myPosition,
                        _zoom,
                        _pan,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                // Кнопки управления зумом.
                Positioned(
                  right: 8,
                  top: 8,
                  child: Column(
                    children: [
                      _ZoomButton(
                        icon: Icons.add,
                        onTap: () => setState(() {
                          _zoom = (_zoom * 1.4).clamp(_minZoom, _maxZoom);
                        }),
                      ),
                      const SizedBox(height: 6),
                      _ZoomButton(
                        icon: Icons.remove,
                        onTap: () => setState(() {
                          _zoom = (_zoom / 1.4).clamp(_minZoom, _maxZoom);
                        }),
                      ),
                      const SizedBox(height: 6),
                      _ZoomButton(icon: Icons.center_focus_strong, onTap: _reset),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text(
            '● Departure · ${widget.departureCode}',
            style: TextStyle(color: accent),
          ),
          Text('● Arrival · ${widget.arrivalCode}', style: TextStyle(color: gold)),
          if (widget.myPosition != null)
            Text('● My position', style: TextStyle(color: const Color(0xFF4ADE80))),
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        'Pinch or scroll to zoom, drag to pan.',
        style: TextStyle(color: textMuted, fontSize: 11),
      ),
    ],
  );
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF091D30).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final SeaRoute route;
  final List<List<List<SeaPoint>>> land;
  final SeaPoint? myPosition;
  final double zoom;
  final Offset pan;

  _RoutePainter(this.route, this.land, this.myPosition, this.zoom, this.pan);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 48 || size.height < 48) return;
    final track = <SeaPoint>[route.points.first];
    for (final point in route.points.skip(1)) {
      final lon = track.last.lon;
      track.add((lat: point.lat, lon: lon + wrapLongitude(point.lon - lon)));
    }

    var west = track.first.lon;
    var east = west;
    var south = track.first.lat;
    var north = south;
    for (final point in track) {
      west = math.min(west, point.lon);
      east = math.max(east, point.lon);
      south = math.min(south, point.lat);
      north = math.max(north, point.lat);
    }
    // Учитываем позицию судна в границах, чтобы точка была видна.
    final my = myPosition;
    if (my != null) {
      west = math.min(west, my.lon);
      east = math.max(east, my.lon);
      south = math.min(south, my.lat);
      north = math.max(north, my.lat);
    }
    final centerLon = (west + east) / 2;
    final centerLat = (south + north) / 2;
    final longitudeScale = math.cos(centerLat * math.pi / 180).clamp(0.15, 1);
    final baseScale = math.min(
      (size.width - 44) / (math.max(east - west, 3) * longitudeScale),
      (size.height - 44) / math.max(north - south, 3),
    );
    final center = Offset(size.width / 2, size.height / 2);

    // Базовая проекция (без зума), затем зум вокруг центра + панорама.
    Offset project(SeaPoint p, [double shift = 0]) {
      final base = Offset(
        center.dx + (p.lon + shift - centerLon) * longitudeScale * baseScale,
        center.dy - (p.lat - centerLat) * baseScale,
      );
      return center + (base - center) * zoom + pan;
    }

    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF091D30));
    final fill = Paint()..color = const Color(0xFF28425B);
    final world = (centerLon / 360).round();
    for (var copy = world - 1; copy <= world + 1; copy++) {
      final shift = copy * 360.0;
      for (final polygon in land) {
        final path = Path()..fillType = PathFillType.evenOdd;
        for (final ring in polygon) {
          path.addPolygon([
            for (final point in ring) project(point, shift),
          ], true);
        }
        if (path.getBounds().overlaps(rect)) canvas.drawPath(path, fill);
      }
    }

    // Подписи стран/регионов — фиксированный размер (не масштабируются).
    for (final label in _countryLabels) {
      final p = project((lat: label.lat, lon: label.lon));
      if (!rect.contains(p)) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: label.name,
          style: const TextStyle(
            color: Color(0xFF9FB4CC),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    final points = track.map((point) => project(point)).toList();
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
    // Маркеры портов — фиксированный размер.
    for (final (point, color) in [
      (points.first, accent),
      (points.last, gold),
    ]) {
      canvas.drawCircle(point, 6, Paint()..color = const Color(0xFF091D30));
      canvas.drawCircle(point, 4, Paint()..color = color);
    }

    // Точка текущей позиции судна (GPS) — фиксированный размер.
    if (my != null) {
      final p = project(my);
      const green = Color(0xFF4ADE80);
      canvas.drawCircle(p, 12, Paint()..color = green.withValues(alpha: 0.18));
      canvas.drawCircle(p, 7, Paint()..color = const Color(0xFF091D30));
      canvas.drawCircle(p, 5, Paint()..color = green);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route ||
      oldDelegate.land != land ||
      oldDelegate.myPosition != myPosition ||
      oldDelegate.zoom != zoom ||
      oldDelegate.pan != pan;
}

/// Крупные страны/регионы для подписей на карте (название + центр).
class _CountryLabel {
  final String name;
  final double lat;
  final double lon;
  const _CountryLabel(this.name, this.lat, this.lon);
}

const List<_CountryLabel> _countryLabels = [
  _CountryLabel('NORWAY', 64.5, 12.0),
  _CountryLabel('SWEDEN', 62.0, 15.0),
  _CountryLabel('FINLAND', 64.0, 26.0),
  _CountryLabel('DENMARK', 56.0, 10.0),
  _CountryLabel('UK', 54.0, -2.5),
  _CountryLabel('IRELAND', 53.2, -8.0),
  _CountryLabel('FRANCE', 46.5, 2.5),
  _CountryLabel('SPAIN', 40.0, -3.5),
  _CountryLabel('PORTUGAL', 39.5, -8.0),
  _CountryLabel('GERMANY', 51.0, 10.0),
  _CountryLabel('POLAND', 52.0, 19.0),
  _CountryLabel('NETHERLANDS', 52.2, 5.5),
  _CountryLabel('BELGIUM', 50.6, 4.5),
  _CountryLabel('ITALY', 42.8, 12.5),
  _CountryLabel('GREECE', 39.0, 22.0),
  _CountryLabel('TURKEY', 39.0, 35.0),
  _CountryLabel('UKRAINE', 49.0, 32.0),
  _CountryLabel('RUSSIA', 60.0, 90.0),
  _CountryLabel('MOROCCO', 31.8, -7.0),
  _CountryLabel('ALGERIA', 28.0, 2.6),
  _CountryLabel('LIBYA', 27.0, 17.0),
  _CountryLabel('EGYPT', 26.8, 30.0),
  _CountryLabel('SAUDI ARABIA', 24.0, 45.0),
  _CountryLabel('YEMEN', 15.5, 47.5),
  _CountryLabel('OMAN', 21.0, 57.0),
  _CountryLabel('UAE', 24.0, 54.0),
  _CountryLabel('IRAN', 32.0, 53.0),
  _CountryLabel('PAKISTAN', 30.0, 69.0),
  _CountryLabel('INDIA', 22.0, 79.0),
  _CountryLabel('SRI LANKA', 7.5, 80.7),
  _CountryLabel('BANGLADESH', 23.7, 90.3),
  _CountryLabel('MYANMAR', 21.0, 96.0),
  _CountryLabel('THAILAND', 15.0, 101.0),
  _CountryLabel('MALAYSIA', 4.0, 102.0),
  _CountryLabel('INDONESIA', -2.0, 118.0),
  _CountryLabel('VIETNAM', 16.0, 107.0),
  _CountryLabel('CHINA', 35.0, 104.0),
  _CountryLabel('JAPAN', 37.0, 138.0),
  _CountryLabel('SOUTH KOREA', 36.5, 127.8),
  _CountryLabel('PHILIPPINES', 12.0, 122.0),
  _CountryLabel('AUSTRALIA', -25.0, 134.0),
  _CountryLabel('NEW ZEALAND', -42.0, 173.0),
  _CountryLabel('SOUTH AFRICA', -29.0, 24.0),
  _CountryLabel('NAMIBIA', -22.0, 17.0),
  _CountryLabel('ANGOLA', -12.0, 17.5),
  _CountryLabel('NIGERIA', 9.0, 8.0),
  _CountryLabel('GHANA', 7.9, -1.0),
  _CountryLabel('SENEGAL', 14.5, -14.5),
  _CountryLabel('BRAZIL', -10.0, -52.0),
  _CountryLabel('ARGENTINA', -35.0, -64.0),
  _CountryLabel('CHILE', -33.0, -71.0),
  _CountryLabel('PERU', -10.0, -76.0),
  _CountryLabel('COLOMBIA', 4.0, -73.0),
  _CountryLabel('VENEZUELA', 7.0, -66.0),
  _CountryLabel('MEXICO', 23.0, -102.0),
  _CountryLabel('USA', 39.0, -98.0),
  _CountryLabel('CANADA', 56.0, -106.0),
  _CountryLabel('GREENLAND', 72.0, -40.0),
  _CountryLabel('ICELAND', 65.0, -18.0),
];
