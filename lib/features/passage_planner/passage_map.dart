import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../deck/port_distance/sea_routes.dart';
import 'passage_route.dart';

class PassageMap extends StatefulWidget {
  const PassageMap({
    super.key,
    required this.land,
    required this.waypoints,
    required this.position,
    required this.next,
    required this.onAdd,
    required this.onMove,
    required this.fitRoute,
  });

  final List<List<List<SeaPoint>>> land;
  final List<PassageWaypoint> waypoints;
  final SeaPoint? position;
  final int? next;
  final ValueChanged<SeaPoint>? onAdd;
  final Future<void> Function(int, SeaPoint)? onMove;
  final bool fitRoute;

  @override
  State<PassageMap> createState() => _PassageMapState();
}

class _PassageMapState extends State<PassageMap> {
  final _transform = TransformationController();
  int? _dragIndex;
  SeaPoint? _draft;
  Offset? _pressStart;
  bool _confirming = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  int? _hit(List<SeaPoint> track, _Projection projection, Offset touch) {
    int? nearest;
    var distance = 18 / _transform.value.getMaxScaleOnAxis();
    for (final (index, point) in track.indexed) {
      final shift = ((projection.center.lon - point.lon) / 360).round() * 360.0;
      final candidate = (projection.project(point, shift) - touch).distance;
      if (candidate < distance) {
        distance = candidate;
        nearest = index;
      }
    }
    return nearest;
  }

  List<SeaPoint> _previewTrack(List<SeaPoint> track) {
    final draft = _draft;
    final index = _dragIndex;
    if (draft == null || index == null || index >= track.length) return track;
    final old = track[index];
    return [...track]
      ..[index] = (
        lat: draft.lat,
        lon: old.lon + wrapLongitude(draft.lon - old.lon),
      );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final track = <SeaPoint>[];
      for (final waypoint in widget.waypoints) {
        final p = waypoint.point;
        final lastLon = track.isEmpty ? p.lon : track.last.lon;
        track.add((lat: p.lat, lon: lastLon + wrapLongitude(p.lon - lastLon)));
      }
      final projection = _Projection(
        size,
        widget.fitRoute ? track : const [],
        widget.fitRoute ? widget.position : null,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 12,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: widget.onAdd == null && widget.onMove == null
                ? null
                : (event) {
                    if (_confirming) return;
                    _pressStart = event.localPosition;
                    _dragIndex = widget.onMove == null
                        ? null
                        : _hit(track, projection, event.localPosition);
                  },
            onLongPressMoveUpdate: (event) {
              final start = _pressStart;
              if (_dragIndex == null || start == null) return;
              final point = projection.unproject(event.localPosition);
              setState(
                () => _draft =
                    (event.localPosition - start).distance >= 3 &&
                        validPassagePoint(point.lat, point.lon)
                    ? point
                    : null,
              );
            },
            onLongPressEnd: (event) async {
              final index = _dragIndex;
              final draft = _draft;
              final start = _pressStart;
              _pressStart = null;
              if (index != null && draft != null) {
                _confirming = true;
                try {
                  await widget.onMove?.call(index, draft);
                } finally {
                  _confirming = false;
                  if (mounted) {
                    setState(() {
                      _dragIndex = null;
                      _draft = null;
                    });
                  }
                }
              } else {
                _dragIndex = null;
                if (index == null &&
                    start != null &&
                    (event.localPosition - start).distance < 3) {
                  final point = projection.unproject(start);
                  if (validPassagePoint(point.lat, point.lon)) {
                    widget.onAdd?.call(point);
                  }
                }
              }
            },
            onLongPressCancel: () {
              if (_confirming) return;
              setState(() {
                _pressStart = null;
                _dragIndex = null;
                _draft = null;
              });
            },
            child: CustomPaint(
              size: size,
              painter: _MapPainter(
                projection,
                widget.land,
                _previewTrack(track),
                widget.position,
                _dragIndex ?? widget.next,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Projection {
  _Projection(this.size, List<SeaPoint> track, SeaPoint? position) {
    if (track.isEmpty) {
      center = position ?? (lat: 0, lon: 0);
      scale = math.min(size.width / 360, size.height / 180);
      return;
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
    if (position != null) {
      final middle = (west + east) / 2;
      final lon = middle + wrapLongitude(position.lon - middle);
      west = math.min(west, lon);
      east = math.max(east, lon);
      south = math.min(south, position.lat);
      north = math.max(north, position.lat);
    }
    center = (lat: (south + north) / 2, lon: (west + east) / 2);
    scale = math.min(
      math.max(1, size.width - 52) / math.max(3, east - west),
      math.max(1, size.height - 52) / math.max(3, north - south),
    );
  }

  final Size size;
  late final SeaPoint center;
  late final double scale;

  Offset project(SeaPoint point, [double shift = 0]) => Offset(
    size.width / 2 + (point.lon + shift - center.lon) * scale,
    size.height / 2 - (point.lat - center.lat) * scale,
  );

  SeaPoint unproject(Offset point) => (
    lat: center.lat - (point.dy - size.height / 2) / scale,
    lon: wrapLongitude(center.lon + (point.dx - size.width / 2) / scale),
  );
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.projection, this.land, this.track, this.position, this.next);

  final _Projection projection;
  final List<List<List<SeaPoint>>> land;
  final List<SeaPoint> track;
  final SeaPoint? position;
  final int? next;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0A2033));
    final landPaint = Paint()..color = const Color(0xFF294653);
    final line = Paint()
      ..color = const Color(0xFF62DFCD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final world = (projection.center.lon / 360).round();
    for (var copy = world - 1; copy <= world + 1; copy++) {
      final shift = copy * 360.0;
      for (final polygon in land) {
        final path = Path()..fillType = PathFillType.evenOdd;
        for (final ring in polygon) {
          path.addPolygon([
            for (final p in ring) projection.project(p, shift),
          ], true);
        }
        if (path.getBounds().overlaps(rect)) canvas.drawPath(path, landPaint);
      }
    }
    if (track.isNotEmpty) {
      final trackWorld = ((projection.center.lon - track.first.lon) / 360)
          .round();
      for (var copy = trackWorld - 1; copy <= trackWorld + 1; copy++) {
        final shift = copy * 360.0;
        final points = [for (final p in track) projection.project(p, shift)];
        canvas.drawPath(Path()..addPolygon(points, false), line);
        Offset? lastLabel;
        for (final (i, point) in points.indexed) {
          if (!rect.inflate(16).contains(point)) continue;
          final selected = i == next;
          canvas.drawCircle(
            point,
            selected ? 5 : 3,
            Paint()..color = selected ? const Color(0xFFFFC66D) : line.color,
          );
          if (selected ||
              i == points.length - 1 ||
              lastLabel == null ||
              (point - lastLabel).distance >= 24) {
            _label(canvas, point + const Offset(6, -16), '${i + 1}');
            lastLabel = point;
          }
        }
      }
    }
    final fix = position;
    if (fix != null) {
      final lon =
          projection.center.lon +
          wrapLongitude(fix.lon - projection.center.lon);
      final p = projection.project((lat: fix.lat, lon: lon));
      canvas.drawCircle(p, 9, Paint()..color = const Color(0xFF0A2033));
      canvas.drawCircle(p, 6, Paint()..color = const Color(0xFF76B8FF));
      _label(canvas, p + const Offset(9, 2), 'POS');
    }
    canvas.restore();
  }

  void _label(Canvas canvas, Offset offset, String value) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.projection != projection ||
      oldDelegate.land != land ||
      oldDelegate.track != track ||
      oldDelegate.position != position ||
      oldDelegate.next != next;
}
