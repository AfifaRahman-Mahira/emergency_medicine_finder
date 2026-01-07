class Medicine {
  final String id;
  final String name;
  final String pharmacyName;
  final double price;

  Medicine({
    required this.id, 
    required this.name, 
    required this.pharmacyName, 
    required this.price
  });

  // এই মেথডটি ডাটা সেভ করার জন্য JSON-এ রূপান্তর করে
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pharmacyName': pharmacyName,
      'price': price,
    };
  }

  // এই মেথডটি JSON থেকে মেডিসিন অবজেক্ট তৈরি করে
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}