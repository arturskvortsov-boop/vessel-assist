import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

typedef SeaPoint = ({double lat, double lon});

SeaPoint readPoint(List<dynamic> pair) =>
    (lon: (pair[0] as num).toDouble(), lat: (pair[1] as num).toDouble());

SeaPoint? portPoint(String value) {
  final match = RegExp(
    r'^\s*(\d{2})(\d{2})([NS])\s*(\d{3})(\d{2})([EW])\s*$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  final latMin = int.parse(match[2]!);
  final lonMin = int.parse(match[5]!);
  final lat = int.parse(match[1]!) + latMin / 60;
  final lon = int.parse(match[4]!) + lonMin / 60;
  if (latMin >= 60 || lonMin >= 60 || lat > 90 || lon > 180) return null;
  return (
    lat: match[3]!.toUpperCase() == 'S' ? -lat : lat,
    lon: match[6]!.toUpperCase() == 'W' ? -lon : lon,
  );
}

double wrapLongitude(double longitude) => (longitude + 180) % 360 - 180;

double distanceNm(SeaPoint a, SeaPoint b) {
  const radians = math.pi / 180;
  final lat = math.sin((b.lat - a.lat) * radians / 2);
  final lon = math.sin(wrapLongitude(b.lon - a.lon) * radians / 2);
  final h =
      lat * lat +
      math.cos(a.lat * radians) * math.cos(b.lat * radians) * lon * lon;
  return 2 * (6371.0088 / 1.852) * math.asin(math.sqrt(h.clamp(0, 1)));
}

class SeaRoute {
  final double miles;
  final List<SeaPoint> points;

  const SeaRoute(this.miles, this.points);
}

typedef _Edge = ({int node, double miles});
typedef _Candidate = ({int node, double priority});

class SeaNetwork {
  final _points = <SeaPoint>[];
  final _edges = <List<_Edge>>[];

  SeaNetwork.fromGeoJson(String source) {
    final indices = <SeaPoint, int>{};
    int indexOf(dynamic coordinate) {
      final point = readPoint(coordinate as List);
      // Merge equivalent longitudes at the date line.
      final normalized = (
        lat: (point.lat * 1e6).round() / 1e6,
        lon: (wrapLongitude(point.lon) * 1e6).round() / 1e6,
      );
      return indices.putIfAbsent(normalized, () {
        _points.add(normalized);
        _edges.add([]);
        return _points.length - 1;
      });
    }

    for (final feature in jsonDecode(source)['features'] as List) {
      final geometry = feature['geometry'];
      final coordinates = geometry['coordinates'] as List;
      final lines = geometry['type'] == 'LineString'
          ? [coordinates]
          : coordinates;
      for (final line in lines) {
        int? previous;
        for (final coordinate in line as List) {
          final current = indexOf(coordinate);
          if (previous != null && previous != current) {
            final miles = distanceNm(_points[previous], _points[current]);
            _edges[previous].add((node: current, miles: miles));
            _edges[current].add((node: previous, miles: miles));
          }
          previous = current;
        }
      }
    }
  }

  int? _nearest(SeaPoint port) {
    int? nearest;
    // Avoid inventing long straight approaches for unsupported ports.
    var limit = 25.0;
    for (var i = 0; i < _points.length; i++) {
      final miles = distanceNm(port, _points[i]);
      if (miles < limit) {
        nearest = i;
        limit = miles;
      }
    }
    return nearest;
  }

  SeaRoute? shortestRoute(SeaPoint from, SeaPoint to) {
    final start = _nearest(from);
    final finish = _nearest(to);
    if (start == null || finish == null || start == finish) return null;

    final miles = List.filled(_points.length, double.infinity);
    final previous = List.filled(_points.length, -1);
    final queue = SplayTreeSet<_Candidate>((a, b) {
      final order = a.priority.compareTo(b.priority);
      return order == 0 ? a.node.compareTo(b.node) : order;
    });
    final target = _points[finish];
    miles[start] = 0;
    queue.add((node: start, priority: distanceNm(_points[start], target)));
    while (queue.isNotEmpty) {
      final entry = queue.first;
      queue.remove(entry);
      final node = entry.node;
      if (node == finish) break;
      if (entry.priority > miles[node] + distanceNm(_points[node], target)) {
        continue;
      }
      for (final edge in _edges[node]) {
        final next = miles[node] + edge.miles;
        if (next >= miles[edge.node]) continue;
        miles[edge.node] = next;
        previous[edge.node] = node;
        queue.add((
          node: edge.node,
          priority: next + distanceNm(_points[edge.node], target),
        ));
      }
    }
    if (!miles[finish].isFinite) return null;

    final track = <SeaPoint>[];
    for (var i = finish; i != -1; i = previous[i]) {
      track.add(_points[i]);
    }
    return SeaRoute(
      distanceNm(from, _points[start]) +
          miles[finish] +
          distanceNm(_points[finish], to),
      [from, ...track.reversed, to],
    );
  }
}
