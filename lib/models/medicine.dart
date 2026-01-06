class Medicine {
  final String name;
  final String pharmacy;
  final String location;
  int stock;
  final String? alternative;

  Medicine({
    required this.name,
    required this.pharmacy,
    required this.location,
    required this.stock,
    this.alternative,
  });
}