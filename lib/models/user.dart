class User {
  final String name; 
  final String email;
  final String password;
  final String role;
  final String? pharmacyName; // এটি আপনার এরর ফিক্স করবে

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.pharmacyName, // কনস্ট্রাক্টরে এটি যোগ করা হয়েছে
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'pharmacyName': pharmacyName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'Patient',
      pharmacyName: map['pharmacyName'],
    );
  }
}