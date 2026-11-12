import 'dart:math' as math;

double normalizeBearing(double degrees) => degrees % 360;

typedef Wind = ({double speed, double? from});

({Wind apparent, Wind trueWind}) calculateTrueWind({
  required double heading,
  required double course,
  required double shipSpeed,
  required double apparentSpeed,
  required double apparentRelativeFrom,
}) {
  final apparentFrom = normalizeBearing(heading + apparentRelativeFrom);
  final apparentAngle = apparentFrom * math.pi / 180;
  final courseAngle = course * math.pi / 180;
  // Wind bearings describe the source, opposite to the velocity vector.
  final east =
      shipSpeed * math.sin(courseAngle) -
      apparentSpeed * math.sin(apparentAngle);
  final north =
      shipSpeed * math.cos(courseAngle) -
      apparentSpeed * math.cos(apparentAngle);
  final scale = math.max(shipSpeed, apparentSpeed);
  final speed = scale == 0
      ? 0.0
      : scale *
            math.sqrt(
              (east / scale) * (east / scale) +
                  (north / scale) * (north / scale),
            );
  final calm = speed <= scale * 1e-12;
  return (
    apparent: (
      speed: apparentSpeed,
      from: apparentSpeed == 0 ? null : apparentFrom,
    ),
    trueWind: (
      speed: calm ? 0 : speed,
      from: calm
          ? null
          : normalizeBearing(math.atan2(-east, -north) * 180 / math.pi),
    ),
  );
}
