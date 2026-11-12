import 'dart:math' as math;

double _normalize(double angle) => angle % 360;

double compassError(double trueBearing, double observed) =>
    (trueBearing - observed + 180) % 360 - 180;

double? landmarkAzimuth(
  double latitude,
  double longitude,
  double landmarkLatitude,
  double landmarkLongitude,
) {
  const rad = math.pi / 180;
  final from = latitude * rad;
  final to = landmarkLatitude * rad;
  final delta = compassError(landmarkLongitude, longitude) * rad;
  final east = math.sin(delta) * math.cos(to);
  final north =
      math.cos(from) * math.sin(to) -
      math.sin(from) * math.cos(to) * math.cos(delta);
  if (east.abs() < 1e-12 && north.abs() < 1e-12) return null;
  return _normalize(math.atan2(east, north) / rad);
}
