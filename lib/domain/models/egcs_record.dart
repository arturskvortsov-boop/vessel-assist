class EgcsRecord {
  final String id;
  final String date;
  final String time;
  final String eventType;
  final String description;
  final String position;
  final String officer;

  EgcsRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.eventType,
    required this.description,
    required this.position,
    required this.officer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'eventType': eventType,
      'description': description,
      'position': position,
      'officer': officer,
    };
  }

  factory EgcsRecord.fromMap(Map<dynamic, dynamic> map) {
    return EgcsRecord(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      eventType: map['eventType'] ?? 'Normal Operation',
      description: map['description'] ?? '',
      position: map['position'] ?? '',
      officer: map['officer'] ?? '',
    );
  }
}