enum UserType { patient, pharmacyOwner, deliveryMan }

class User {
  final String email;
  final String password;
  final UserType type;

  User({
    required this.email,
    required this.password,
    required this.type,
  });
}
