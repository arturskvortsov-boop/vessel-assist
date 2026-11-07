class FuelLog {
  final String id;
  final String date;
  final String time;
  final String event;
  final double bunker;
  final double rob;

  final double meCurr;
  final double meMT;
  final double meDens;
  final double meTemp;
  
  final double dgCurr;
  final double dgOutCurr;
  final double dgMT;
  final double dgDens;
  final double dgTemp;
  final double dgOutDens;
  final double dgOutTemp;
  
  final double blrCurr;
  final double blrMT;
  final double blrDens;
  final double blrTemp;
  
  final double commonCurr;
  final double commonMT;
  final double commonDens;
  final double commonTemp;

  FuelLog({
    required this.id, required this.date, required this.time, required this.event,
    required this.bunker, required this.rob,
    required this.meCurr, required this.meMT, required this.meDens, required this.meTemp,
    required this.dgCurr, required this.dgOutCurr, required this.dgMT, required this.dgDens, required this.dgTemp, required this.dgOutDens, required this.dgOutTemp,
    required this.blrCurr, required this.blrMT, required this.blrDens, required this.blrTemp,
    required this.commonCurr, required this.commonMT, required this.commonDens, required this.commonTemp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'date': date, 'time': time, 'event': event,
      'bunker': bunker, 'rob': rob,
      'meCurr': meCurr, 'meMT': meMT, 'meDens': meDens, 'meTemp': meTemp,
      'dgCurr': dgCurr, 'dgOutCurr': dgOutCurr, 'dgMT': dgMT, 'dgDens': dgDens, 'dgTemp': dgTemp, 'dgOutDens': dgOutDens, 'dgOutTemp': dgOutTemp,
      'blrCurr': blrCurr, 'blrMT': blrMT, 'blrDens': blrDens, 'blrTemp': blrTemp,
      'commonCurr': commonCurr, 'commonMT': commonMT, 'commonDens': commonDens, 'commonTemp': commonTemp,
    };
  }

  factory FuelLog.fromMap(Map<dynamic, dynamic> map) {
    return FuelLog(
      id: map['id'] ?? '', date: map['date'] ?? '', time: map['time'] ?? '12:00', event: map['event'] ?? 'NOON',
      bunker: (map['bunker'] as num?)?.toDouble() ?? 0.0, rob: (map['rob'] as num?)?.toDouble() ?? 0.0,
      meCurr: (map['meCurr'] as num?)?.toDouble() ?? 0.0, meMT: (map['meMT'] as num?)?.toDouble() ?? 0.0, meDens: (map['meDens'] as num?)?.toDouble() ?? 0.9455, meTemp: (map['meTemp'] as num?)?.toDouble() ?? 15.0,
      dgCurr: (map['dgCurr'] as num?)?.toDouble() ?? 0.0, dgOutCurr: (map['dgOutCurr'] as num?)?.toDouble() ?? 0.0, dgMT: (map['dgMT'] as num?)?.toDouble() ?? 0.0, dgDens: (map['dgDens'] as num?)?.toDouble() ?? 0.9455, dgTemp: (map['dgTemp'] as num?)?.toDouble() ?? 15.0, dgOutDens: (map['dgOutDens'] as num?)?.toDouble() ?? 0.9455, dgOutTemp: (map['dgOutTemp'] as num?)?.toDouble() ?? 15.0,
      blrCurr: (map['blrCurr'] as num?)?.toDouble() ?? 0.0, blrMT: (map['blrMT'] as num?)?.toDouble() ?? 0.0, blrDens: (map['blrDens'] as num?)?.toDouble() ?? 0.9455, blrTemp: (map['blrTemp'] as num?)?.toDouble() ?? 15.0,
      commonCurr: (map['commonCurr'] as num?)?.toDouble() ?? 0.0, commonMT: (map['commonMT'] as num?)?.toDouble() ?? 0.0, commonDens: (map['commonDens'] as num?)?.toDouble() ?? 0.9455, commonTemp: (map['commonTemp'] as num?)?.toDouble() ?? 15.0,
    );
  }
}