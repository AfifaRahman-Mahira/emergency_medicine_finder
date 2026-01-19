class User {
  final String name; 
  final String email;
  final String password;
  final String role;
  final String? pharmacyName; 

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.pharmacyName,
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