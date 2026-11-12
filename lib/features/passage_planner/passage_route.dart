import 'dart:convert';

import 'package:xml/xml.dart';

import '../deck/port_distance/sea_routes.dart';

class PassageWaypoint {
  const PassageWaypoint(this.name, this.point);

  final String name;
  final SeaPoint point;

  Map<String, Object> toJson() => {
    'name': name,
    'lat': point.lat,
    'lon': point.lon,
  };
}

bool validPassagePoint(double lat, double lon) =>
    lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180;

class PassageRoute {
  PassageRoute(this.name, Iterable<PassageWaypoint> waypoints)
    : waypoints = List.unmodifiable(waypoints);

  final String name;
  final List<PassageWaypoint> waypoints;

  double get totalDistance => distanceFromWaypoint(0);

  double distanceFromWaypoint(int index) {
    var distance = 0.0;
    for (var i = index + 1; i < waypoints.length; i++) {
      distance += distanceNm(waypoints[i - 1].point, waypoints[i].point);
    }
    return distance;
  }

  double remainingDistance(SeaPoint position, int next) =>
      distanceNm(position, waypoints[next].point) + distanceFromWaypoint(next);

  Map<String, Object> toJson() => {
    'name': name,
    'waypoints': [for (final waypoint in waypoints) waypoint.toJson()],
  };

  factory PassageRoute.fromJson(Map<String, dynamic> json) {
    final points = <PassageWaypoint>[];
    for (final item in json['waypoints'] as List) {
      final lat = (item['lat'] as num).toDouble();
      final lon = (item['lon'] as num).toDouble();
      if (!validPassagePoint(lat, lon)) {
        throw const FormatException('Invalid position.');
      }
      points.add(PassageWaypoint(item['name'] as String, (lat: lat, lon: lon)));
    }
    return PassageRoute(json['name'] as String, points);
  }
}

PassageRoute parseRt3(List<int> bytes, {required String fallbackName}) {
  if (bytes.length > 2 * 1024 * 1024) {
    throw const FormatException('The RT3 file is too large.');
  }
  final String source;
  try {
    source = utf8.decode(bytes);
  } on FormatException {
    throw const FormatException('This RT3 text encoding is unsupported.');
  }
  final XmlDocument document;
  try {
    document = XmlDocument.parse(source.replaceFirst(RegExp(r'^\uFEFF'), ''));
  } on XmlException {
    throw const FormatException('The file is not readable Transas RT3 XML.');
  }
  final root = document.rootElement;
  final group = root.getElement('WayPoints');
  if (root.name.local != 'TSH_Route' ||
      root.getAttribute('RtVersion') != '3' ||
      group == null) {
    throw const FormatException('Choose a Transas RT3 route (version 3).');
  }
  final points = <PassageWaypoint>[];
  for (final element in group.findElements('WayPoint')) {
    final lat = double.tryParse(element.getAttribute('Lat') ?? '')?.toDouble();
    final lon = double.tryParse(element.getAttribute('Lon') ?? '')?.toDouble();
    if (lat == null || lon == null || !validPassagePoint(lat / 60, lon / 60)) {
      throw FormatException(
        'Invalid coordinates at waypoint ${points.length + 1}.',
      );
    }
    final name = element.getAttribute('WPName')?.trim();
    points.add(
      PassageWaypoint(
        name == null || name.isEmpty ? 'WP ${points.length + 1}' : name,
        (lat: lat / 60, lon: lon / 60),
      ),
    );
  }
  if (points.isEmpty ||
      int.tryParse(group.getAttribute('WPCount') ?? '') != points.length) {
    throw const FormatException(
      'The waypoint count in this RT3 file does not match.',
    );
  }
  final name = root.getAttribute('RtName')?.trim();
  return PassageRoute(
    name == null || name.isEmpty ? fallbackName : name,
    points,
  );
}
