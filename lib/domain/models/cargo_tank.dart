class CargoTank {
  final String id;
  final String name;
  final String fuelType;
  final double capacityM3;
  final double volumeM3;
  final double densityMtPerM3;
  final String updatedAt;

  CargoTank({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.capacityM3,
    required this.volumeM3,
    required this.densityMtPerM3,
    required this.updatedAt,
  });

  double get massMT => volumeM3 * densityMtPerM3;
  double get fillPercentage => capacityM3 > 0 ? (volumeM3 / capacityM3) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fuelType': fuelType,
      'capacityM3': capacityM3,
      'volumeM3': volumeM3,
      'densityMtPerM3': densityMtPerM3,
      'updatedAt': updatedAt,
    };
  }

  factory CargoTank.fromMap(Map<dynamic, dynamic> map) {
    return CargoTank(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      fuelType: map['fuelType'] ?? '',
      capacityM3: (map['capacityM3'] as num?)?.toDouble() ?? 0.0,
      volumeM3: (map['volumeM3'] as num?)?.toDouble() ?? 0.0,
      densityMtPerM3: (map['densityMtPerM3'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] ?? '',
    );
  }
}