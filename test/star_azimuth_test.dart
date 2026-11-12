import 'package:flutter_test/flutter_test.dart';
import 'package:vessel_assist/features/deck/compass_error/landmark_bearing.dart';
import 'package:vessel_assist/features/deck/compass_error/nav_stars.dart';
import 'package:vessel_assist/features/deck/compass_error/star_azimuth.dart';

void main() {
  test('Offline azimuths match USNO in both hemispheres', () {
    final north = StarSky(DateTime.utc(2026, 11, 12, 1), 54.4, 18.7);
    final south = StarSky(DateTime.utc(2027, 3, 4, 9, 30, 15), -34, 151);
    expect(navStars.map((star) => star.name).toSet(), hasLength(58));
    // USNO Celestial Navigation API, at the UTC times and positions above.
    for (final (sky, name, azimuth, altitude) in [
      (north, 'Polaris', 359.339220, 54.891337),
      (north, 'Sirius', 163.231389, 17.430978),
      (south, 'Canopus', 178.762826, 71.279423),
      (south, 'Acrux', 148.943260, 29.289588),
    ]) {
      final sight = sky.aboveHorizon.singleWhere(
        (sight) => sight.star.name == name,
      );
      expect(compassError(sight.azimuth, azimuth).abs(), lessThan(0.05));
      expect(sight.altitude, closeTo(altitude, 0.03));
    }
    expect(
      south.aboveHorizon.any((sight) => sight.star.name == 'Polaris'),
      isFalse,
    );
  });

  test('Compass correction crosses true north in either direction', () {
    expect(compassError(1, 358), 3);
    expect(compassError(358, 1), -3);
  });
}
