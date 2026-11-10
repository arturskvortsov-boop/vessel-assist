class Note {
  final String id;
  final String title;
  final String body;
  final String category;
  bool isPinned;
  final int timestamp;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isPinned,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'title': title, 'body': body, 'category': category,
      'isPinned': isPinned, 'timestamp': timestamp,
    };
  }

  factory Note.fromMap(Map<dynamic, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      category: map['category'] ?? 'General',
      isPinned: map['isPinned'] ?? false,
      timestamp: map['timestamp'] ?? 0,
    );
  }
}