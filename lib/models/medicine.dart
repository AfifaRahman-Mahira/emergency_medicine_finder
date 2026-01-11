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
    required this.alternatives,
  });
}