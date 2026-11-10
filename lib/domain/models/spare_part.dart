class SparePart {
  final String id;
  final String name;
  final String maker;
  final String partNo;
  final String location;
  final String category;
  double onBoard;
  double minQty;
  double ordered;
  bool isCritical;

  SparePart({
    required this.id,
    required this.name,
    required this.maker,
    required this.partNo,
    required this.location,
    required this.category,
    required this.onBoard,
    required this.minQty,
    required this.ordered,
    required this.isCritical,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'name': name, 'maker': maker, 'partNo': partNo, 
      'location': location, 'category': category, 'onBoard': onBoard, 
      'minQty': minQty, 'ordered': ordered, 'isCritical': isCritical,
    };
  }

  factory SparePart.fromMap(Map<dynamic, dynamic> map) {
    return SparePart(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      maker: map['maker'] ?? '',
      partNo: map['partNo'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? 'Spare',
      onBoard: (map['onBoard'] as num?)?.toDouble() ?? 0.0,
      minQty: (map['minQty'] as num?)?.toDouble() ?? 0.0,
      ordered: (map['ordered'] as num?)?.toDouble() ?? 0.0,
      isCritical: map['isCritical'] ?? false,
    );
  }
}