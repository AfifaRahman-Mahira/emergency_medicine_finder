class Medicine {
  final String id;
  final String name;
  final String generic;
  final String genericName;
  final double price;
  int stock;
  final String pharmacyName;
  final String location;
  final double distance;
  final double? lat; // Added for real-time location tracking
  final double? lng; // Added for real-time location tracking
  final List<String> alternatives;

  Medicine({
    required this.id,
    required this.name,
    required this.generic,
    required this.genericName,
    required this.price,
    required this.stock,
    required this.pharmacyName,
    required this.location,
    required this.distance,
    this.lat,
    this.lng,
    required this.alternatives,
  });

  // Convert Medicine object to Map (JSON) for saving
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'generic': generic,
      'genericName': genericName,
      'price': price,
      'stock': stock,
      'pharmacyName': pharmacyName,
      'location': location,
      'distance': distance,
      'lat': lat,
      'lng': lng,
      'alternatives': alternatives,
    };
  }

  // Create Medicine object from Map (JSON) when loading
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      generic: map['generic'] ?? '',
      genericName: map['genericName'] ?? '',
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] ?? 0,
      pharmacyName: map['pharmacyName'] ?? '',
      location: map['location'] ?? '',
      distance: (map['distance'] as num).toDouble(),
      lat: map['lat'],
      lng: map['lng'],
      alternatives: List<String>.from(map['alternatives'] ?? []),
    );
  }
}