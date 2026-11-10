class OrbEntry {
  final String id;
  final String code;
  final String date;
  final String text;
  final int timestamp;

  OrbEntry({required this.id, required this.code, required this.date, required this.text, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'id': id, 'code': code, 'date': date, 'text': text, 'timestamp': timestamp};
  }

  factory OrbEntry.fromMap(Map<dynamic, dynamic> map) {
    return OrbEntry(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      date: map['date'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}