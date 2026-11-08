class EmergencyProcedure {
  final String id;
  final String title;
  final String steps;

  EmergencyProcedure({required this.id, required this.title, required this.steps});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'steps': steps};

  factory EmergencyProcedure.fromMap(Map<dynamic, dynamic> map) => EmergencyProcedure(
    id: map['id'] ?? '', title: map['title'] ?? '', steps: map['steps'] ?? '',
  );
}