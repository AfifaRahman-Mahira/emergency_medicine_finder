class Medicine {
  final String id;
  final String name;
  final String genericName; // বিকল্প ওষুধ খোঁজার জন্য (যেমন: Paracetamol)
  final String pharmacyName;
  final double price;
  int stock; // স্টকের পরিমাণ
  final String location; // ফার্মেসির ঠিকানা
  double distance; // ইউজার থেকে দূরত্ব (কিমি)

  Medicine({
    required this.id,
    required this.name,
    required this.genericName, // নতুন যুক্ত
    required this.pharmacyName,
    required this.price,
    this.stock = 0, // ডিফল্ট ০ থাকবে
    this.location = "Unknown", // নতুন যুক্ত
    this.distance = 0.0, // নতুন যুক্ত
  });

  // ডাটাবেসে সেভ করার জন্য
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'pharmacyName': pharmacyName,
      'price': price,
      'stock': stock,
      'location': location,
      'distance': distance,
    };
  }

  // ডাটাবেস থেকে ডাটা পড়ার জন্য
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      genericName: map['genericName'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      location: map['location'] ?? 'Unknown',
      distance: (map['distance'] ?? 0.0).toDouble(),
    );
  }
}