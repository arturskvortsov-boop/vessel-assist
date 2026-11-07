class FuelLog {
  final String id;
  final String date;
  final String time;
  final String event;
  final double bunker;
  final double rob;

  final double meCurr;
  final double meMT;
  
  final double dgCurr;
  final double dgMT;
  
  final double blrCurr;
  final double blrMT;

  FuelLog({
    required this.id,
    required this.date,
    required this.time,
    required this.event,
    required this.bunker,
    required this.rob,
    required this.meCurr,
    required this.meMT,
    required this.dgCurr,
    required this.dgMT,
    required this.blrCurr,
    required this.blrMT,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'event': event,
      'bunker': bunker,
      'rob': rob,
      'meCurr': meCurr,
      'meMT': meMT,
      'dgCurr': dgCurr,
      'dgMT': dgMT,
      'blrCurr': blrCurr,
      'blrMT': blrMT,
    };
  }

  factory FuelLog.fromMap(Map<dynamic, dynamic> map) {
    return FuelLog(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '12:00',
      event: map['event'] ?? 'NOON',
      bunker: (map['bunker'] as num?)?.toDouble() ?? 0.0,
      rob: (map['rob'] as num?)?.toDouble() ?? 0.0,
      meCurr: (map['meCurr'] as num?)?.toDouble() ?? 0.0,
      meMT: (map['meMT'] as num?)?.toDouble() ?? 0.0,
      dgCurr: (map['dgCurr'] as num?)?.toDouble() ?? 0.0,
      dgMT: (map['dgMT'] as num?)?.toDouble() ?? 0.0,
      blrCurr: (map['blrCurr'] as num?)?.toDouble() ?? 0.0,
      blrMT: (map['blrMT'] as num?)?.toDouble() ?? 0.0,
    );
  }
}