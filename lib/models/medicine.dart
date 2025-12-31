class Medicine {
  final String name;
  final String pharmacy;
  int stock;
  final String? alternative;

  Medicine({
    required this.name,
    required this.pharmacy,
    required this.stock,
    this.alternative,
  });
}
