import 'dart:math' as math;

import 'nav_stars.dart';

const _rad = math.pi / 180;
double _sin(double degrees) => math.sin(degrees * _rad);
double _cos(double degrees) => math.cos(degrees * _rad);
double _asin(double value) => math.asin(value.clamp(-1, 1)) / _rad;
double _atan(double y, double x) => math.atan2(y, x) / _rad;

typedef StarSight = ({
  NavStar star,
  double ghaAries,
  double sha,
  double gha,
  double declination,
  double lha,
  double altitude,
  double azimuth,
});

class StarSky {
  StarSky(DateTime utc, this.latitude, this.longitude)
    : days = utc.millisecondsSinceEpoch / 86400000 - 10957.5;

  final double latitude;
  final double longitude;
  final double days;
  double get _t => days / 36525;

  double get _sunLongitude => (280.4665 + 0.98564736 * days) % 360;
  double get _node => (125.04452 - 1934.136261 * _t) % 360;
  double get _moonLongitude => (218.3165 + 481267.8813 * _t) % 360;
  double get _obliquity => 23.439291 - 0.0130042 * _t;
  double get _nutationLongitude =>
      (-17.20 * _sin(_node) -
          1.32 * _sin(2 * _sunLongitude) -
          0.23 * _sin(2 * _moonLongitude) +
          0.21 * _sin(2 * _node)) /
      3600;
  double get _nutationObliquity =>
      (9.20 * _cos(_node) +
          0.57 * _cos(2 * _sunLongitude) +
          0.10 * _cos(2 * _moonLongitude) -
          0.09 * _cos(2 * _node)) /
      3600;

  // UTC approximates UT1. The equation of the equinoxes uses the dominant
  // nutation terms. Stellar aberration and parallax are omitted.
  double get ghaAries =>
      (280.46061837 +
          360.98564736629 * days +
          0.000387933 * _t * _t -
          _t * _t * _t / 38710000 +
          _nutationLongitude * _cos(_obliquity)) %
      360;

  ({double altitude, double azimuth}) _horizontal(double dec, double lha) {
    final east = -_cos(dec) * _sin(lha);
    final north =
        _sin(dec) * _cos(latitude) - _cos(dec) * _cos(lha) * _sin(latitude);
    final up =
        _sin(dec) * _sin(latitude) + _cos(dec) * _cos(lha) * _cos(latitude);
    return (altitude: _asin(up), azimuth: _atan(east, north) % 360);
  }

  double get sunAltitude {
    final anomaly = 357.529 + 0.98560028 * days;
    final lambda =
        _sunLongitude + 1.915 * _sin(anomaly) + 0.020 * _sin(2 * anomaly);
    final ra = _atan(_cos(_obliquity) * _sin(lambda), _cos(lambda));
    final dec = _asin(_sin(_obliquity) * _sin(lambda));
    return _horizontal(dec, ghaAries - ra + longitude).altitude;
  }

  StarSight sight(NavStar star) {
    final t = _t;
    final ra =
        star.raHours * 15 + star.pmRa * t * 100 / (3600000 * _cos(star.dec));
    final dec = star.dec + star.pmDec * t * 100 / 3600000;
    // IAU 1976 precession from J2000 to the observation date.
    final zeta =
        (2306.2181 * t + 0.30188 * t * t + 0.017998 * t * t * t) / 3600;
    final z = (2306.2181 * t + 1.09468 * t * t + 0.018203 * t * t * t) / 3600;
    final theta =
        (2004.3109 * t - 0.42665 * t * t - 0.041833 * t * t * t) / 3600;
    final a = _cos(dec) * _sin(ra + zeta);
    final b =
        _cos(theta) * _cos(dec) * _cos(ra + zeta) - _sin(theta) * _sin(dec);
    final c =
        _sin(theta) * _cos(dec) * _cos(ra + zeta) + _cos(theta) * _sin(dec);
    final meanRa = _atan(a, b) + z;
    final meanDec = _asin(c);
    final x = _cos(meanDec) * _cos(meanRa);
    final y = _cos(meanDec) * _sin(meanRa);
    final obliquity = _obliquity;
    final eclipticY = y * _cos(obliquity) + c * _sin(obliquity);
    final eclipticZ = -y * _sin(obliquity) + c * _cos(obliquity);
    final psi = _nutationLongitude;
    final apparentX = x * _cos(psi) - eclipticY * _sin(psi);
    final rotatedY = x * _sin(psi) + eclipticY * _cos(psi);
    final eps = obliquity + _nutationObliquity;
    final apparentY = rotatedY * _cos(eps) - eclipticZ * _sin(eps);
    final apparentDec = _asin(rotatedY * _sin(eps) + eclipticZ * _cos(eps));
    final sha = (-_atan(apparentY, apparentX)) % 360;
    final aries = ghaAries;
    final gha = (aries + sha) % 360;
    final lha = (gha + longitude) % 360;
    final horizontal = _horizontal(apparentDec, lha);
    return (
      star: star,
      ghaAries: aries,
      sha: sha,
      gha: gha,
      declination: apparentDec,
      lha: lha,
      altitude: horizontal.altitude,
      azimuth: horizontal.azimuth,
    );
  }

  List<StarSight> get aboveHorizon =>
      navStars.map(sight).where((sight) => sight.altitude > 0).toList()
        ..sort((a, b) => a.star.magnitude.compareTo(b.star.magnitude));
}
