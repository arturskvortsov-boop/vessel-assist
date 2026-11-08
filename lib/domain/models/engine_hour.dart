class EngineHour {
  final String id;
  final String name;
  final String group;
  final double currentHours;
  final List<Map<String, dynamic>> history;

  EngineHour({
    required this.id,
    required this.name,
    required this.group,
    required this.currentHours,
    required this.history,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'currentHours': currentHours,
      'history': history,
    };
  }

  factory EngineHour.fromMap(Map<dynamic, dynamic> map) {
    return EngineHour(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      group: map['group'] ?? 'Other',
      currentHours: (map['currentHours'] as num?)?.toDouble() ?? 0.0,
      history: List<Map<String, dynamic>>.from(map['history'] ?? []),
    );
  }
}