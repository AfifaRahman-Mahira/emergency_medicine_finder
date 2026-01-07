class Medicine {
  String id;
  String name;
  String pharmacyName;
  String location;
  double price;
  int stock;
  String alternative;

  Medicine({
    required this.id,
    required this.name,
    required this.pharmacyName,
    required this.location,
    required this.price,
    required this.stock,
    this.alternative = "No alternative suggested",
  });
}
