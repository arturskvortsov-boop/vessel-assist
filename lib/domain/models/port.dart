class Port {
  final String code;
  final String name;
  final String country;
  final String coordinates;
  final String searchString;

  Port({
    required this.code,
    required this.name,
    required this.country,
    required this.coordinates,
    required this.searchString,
  });

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      coordinates: json['coordinates'] ?? '',
      searchString: (json['search'] ?? '').toString().toLowerCase(),
    );
  }
}