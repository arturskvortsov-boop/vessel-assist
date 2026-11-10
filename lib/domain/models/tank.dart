class Tank {
  final String id;
  final String name;
  final String type;
  final double capacity;
  double volume;
  double density;
  double temp;

  Tank({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    this.volume = 0.0,
    this.density = 0.95,
    this.temp = 15.0,
  });

  // Преобразование в Map для сохранения в Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'capacity': capacity,
      'volume': volume,
      'density': density,
      'temp': temp,
    };
  }

  // Восстановление из Map
  factory Tank.fromMap(Map<dynamic, dynamic> map) {
    return Tank(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      capacity: (map['capacity'] as num).toDouble(),
      volume: (map['volume'] as num).toDouble(),
      density: (map['density'] as num).toDouble(),
      temp: (map['temp'] as num).toDouble(),
    );
  }
}