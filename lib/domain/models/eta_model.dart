class EtaResult {
  final double distanceNM;
  final double averageSpeedKnots;
  final DateTime departureUTC;
  final DateTime arrivalUTC;
  final bool requiredSpeedMode;
  
  const EtaResult._({
    required this.distanceNM, 
    required this.averageSpeedKnots,
    required this.departureUTC, 
    required this.arrivalUTC, 
    required this.requiredSpeedMode
  });
  
  Duration get duration => arrivalUTC.difference(departureUTC);
  
  static void _distance(double d) {
    if (!d.isFinite || d <= 0) throw const FormatException('Distance must be greater than zero.');
  }
  
  factory EtaResult.calculateEta({
    required double distanceNM,
    required double speedKnots,
    required DateTime departureUTC,
  }) {
    _distance(distanceNM);
    if (!speedKnots.isFinite || speedKnots <= 0) throw const FormatException('Speed must be greater than zero.');
    final micros = distanceNM / speedKnots * Duration.microsecondsPerHour;
    if (!micros.isFinite || micros < 1 || micros > 36525 * Duration.microsecondsPerDay) {
      throw const FormatException('Voyage duration must be between 1 microsecond and 100 years.');
    }
    final departure = departureUTC.toUtc();
    final arrival = departure.add(Duration(microseconds: micros.ceil()));
    return EtaResult._(distanceNM: distanceNM, averageSpeedKnots: speedKnots,
      departureUTC: departure, arrivalUTC: arrival, requiredSpeedMode: false);
  }
  
  factory EtaResult.requiredSpeed({
    required double distanceNM,
    required DateTime departureUTC,
    required DateTime targetArrivalUTC
  }) {
    _distance(distanceNM);
    final departure = departureUTC.toUtc(), arrival = targetArrivalUTC.toUtc();
    final micros = arrival.difference(departure).inMicroseconds;
    if (micros <= 0) throw const FormatException('Target arrival must be later than departure in UTC.');
    final speed = distanceNM / (micros / Duration.microsecondsPerHour);
    if (!speed.isFinite || speed <= 0) throw const FormatException('Check distance and available time.');
    return EtaResult._(distanceNM: distanceNM, averageSpeedKnots: speed,
      departureUTC: departure, arrivalUTC: arrival, requiredSpeedMode: true);
  }
  
  double get requiredSpeedRounded => (averageSpeedKnots * 100).ceilToDouble() / 100;
}

DateTime portTimeToUtc(DateTime wallTime, int utcOffsetMinutes) {
  if (utcOffsetMinutes < -720 || utcOffsetMinutes > 840 || utcOffsetMinutes % 15 != 0) {
    throw const FormatException('Use a UTC offset from -12:00 to +14:00 in 15-minute steps.');
  }
  return DateTime.utc(wallTime.year, wallTime.month, wallTime.day, wallTime.hour, wallTime.minute, wallTime.second, wallTime.millisecond, wallTime.microsecond).subtract(Duration(minutes: utcOffsetMinutes));
}

DateTime utcToPortTime(DateTime utc, int utcOffsetMinutes) {
  return utc.toUtc().add(Duration(minutes: utcOffsetMinutes));
}

String etaOffsetLabel(int minutes) {
  if (minutes == 0) return 'UTC';
  final m = minutes.abs();
  return 'UTC${minutes >= 0 ? '+' : '-'}${(m ~/ 60).toString().padLeft(2,'0')}:${(m % 60).toString().padLeft(2,'0')}';
}

String etaDateTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2,'0');
  return '${two(time.day)}.${two(time.month)}.${time.year} ${two(time.hour)}:${two(time.minute)}';
}

String etaDuration(Duration time) {
  final seconds = (time.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  return '${seconds ~/ 86400} d ${(seconds ~/ 3600) % 24} h ${(seconds ~/ 60) % 60} min';
}