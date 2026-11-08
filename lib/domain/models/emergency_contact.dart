class EmergencyContact {
  final String id;
  final String role;
  final String name;
  final String phone;

  EmergencyContact({required this.id, required this.role, required this.name, required this.phone});

  Map<String, dynamic> toMap() => {'id': id, 'role': role, 'name': name, 'phone': phone};

  factory EmergencyContact.fromMap(Map<dynamic, dynamic> map) => EmergencyContact(
    id: map['id'] ?? '', role: map['role'] ?? '', name: map['name'] ?? '', phone: map['phone'] ?? '',
  );
}