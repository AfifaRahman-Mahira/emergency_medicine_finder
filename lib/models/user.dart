class User {
  String email;
  String password;
  String role;
  String? pharmacyName; // এই লাইনটা মাস্ট!

  User({
    required this.email,
    required this.password,
    required this.role,
    this.pharmacyName, // এখানেও এড করলাম
  });
}