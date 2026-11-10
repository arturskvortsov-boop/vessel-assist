class WarrantyClaim {
  final String id;
  final String item;
  final String maker;
  final String system;
  final String description;
  final String dateFail;
  final String dateClaimed;
  final String refNo;
  final String expiry;
  String status;
  final String notes;

  WarrantyClaim({
    required this.id,
    required this.item,
    required this.maker,
    required this.system,
    required this.description,
    required this.dateFail,
    required this.dateClaimed,
    required this.refNo,
    required this.expiry,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'item': item, 'maker': maker, 'system': system, 
      'description': description, 'dateFail': dateFail, 'dateClaimed': dateClaimed, 
      'refNo': refNo, 'expiry': expiry, 'status': status, 'notes': notes,
    };
  }

  factory WarrantyClaim.fromMap(Map<dynamic, dynamic> map) {
    return WarrantyClaim(
      id: map['id'] ?? '',
      item: map['item'] ?? '',
      maker: map['maker'] ?? '',
      system: map['system'] ?? 'Other',
      description: map['description'] ?? '',
      dateFail: map['dateFail'] ?? '',
      dateClaimed: map['dateClaimed'] ?? '',
      refNo: map['refNo'] ?? '',
      expiry: map['expiry'] ?? '',
      status: map['status'] ?? 'Open',
      notes: map['notes'] ?? '',
    );
  }
}