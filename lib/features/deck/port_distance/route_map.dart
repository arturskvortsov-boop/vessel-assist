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

class RouteMap extends StatelessWidget {
  final SeaRoute route;
  final List<List<List<SeaPoint>>> land;
  final String departureCode;
  final String arrivalCode;

  const RouteMap({
    super.key,
    required this.route,
    required this.land,
    required this.departureCode,
    required this.arrivalCode,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        image: true,
        label: 'Approximate sea route from $departureCode to $arrivalCode',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 250,
            child: CustomPaint(painter: _RoutePainter(route, land)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text(
            '● Departure · $departureCode',
            style: const TextStyle(color: accent),
          ),
          Text('● Arrival · $arrivalCode', style: const TextStyle(color: gold)),
        ],
      ),
    ],
  );
}

class _RoutePainter extends CustomPainter {
  final SeaRoute route;
  final List<List<List<SeaPoint>>> land;

  _RoutePainter(this.route, this.land);

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
    final centerLon = (west + east) / 2;
    final centerLat = (south + north) / 2;
    final longitudeScale = math.cos(centerLat * math.pi / 180).clamp(0.15, 1);
    final scale = math.min(
      (size.width - 44) / (math.max(east - west, 3) * longitudeScale),
      (size.height - 44) / math.max(north - south, 3),
    );
    Offset project(SeaPoint p, [double shift = 0]) => Offset(
      size.width / 2 + (p.lon + shift - centerLon) * longitudeScale * scale,
      size.height / 2 - (p.lat - centerLat) * scale,
    );

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
    final points = track.map((point) => project(point)).toList();
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
    for (final (point, color) in [
      (points.first, accent),
      (points.last, gold),
    ]) {
      canvas.drawCircle(point, 6, Paint()..color = const Color(0xFF091D30));
      canvas.drawCircle(point, 4, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.land != land;
}
