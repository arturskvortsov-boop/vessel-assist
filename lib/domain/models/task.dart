class Task {
  final String id;
  final String name;
  final String assignee;
  final String priority;
  final String deadline;
  String status;
  final int timestamp;

  Task({
    required this.id,
    required this.name,
    required this.assignee,
    required this.priority,
    required this.deadline,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'assignee': assignee,
      'priority': priority,
      'deadline': deadline,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory Task.fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      assignee: map['assignee'] ?? '',
      priority: map['priority'] ?? 'Medium',
      deadline: map['deadline'] ?? '',
      status: map['status'] ?? 'Open',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}