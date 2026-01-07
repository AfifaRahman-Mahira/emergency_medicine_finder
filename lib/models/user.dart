class User {
  final String email;
  final String password;
  final String role;
  final String? pharmacyName;

  User({required this.email, required this.password, required this.role, this.pharmacyName});

  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'role': role,
    'pharmacyName': pharmacyName,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    email: map['email'],
    password: map['password'],
    role: map['role'],
    pharmacyName: map['pharmacyName'],
  );
}