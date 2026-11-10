class PunchItem {
  final String id;
  final String item;
  final String location;
  final String description;
  final String severity;
  String status;
  final String responsible;

  PunchItem({
    required this.id,
    required this.item,
    required this.location,
    required this.description,
    required this.severity,
    required this.status,
    required this.responsible,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'item': item, 'location': location, 'description': description,
      'severity': severity, 'status': status, 'responsible': responsible,
    };
  }

  factory PunchItem.fromMap(Map<dynamic, dynamic> map) {
    return PunchItem(
      id: map['id'] ?? '',
      item: map['item'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'Minor',
      status: map['status'] ?? 'Open',
      responsible: map['responsible'] ?? '',
    );
  }
}