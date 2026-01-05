import '../models/medicine.dart';

// Dummy users (email & password)
final List<Map<String, String>> users = [
  {
    'email': 'patient@test.com',
    'password': '123456',
    'role': 'patient',
  },
  {
    'email': 'pharmacy@test.com',
    'password': '123456',
    'role': 'pharmacy',
  },
];

// Medicine list
final List<Medicine> medicines = [
  Medicine(
    name: 'Paracetamol',
    pharmacy: 'ABC Pharmacy',
    stock: 10,
    price: 10,
  ),
  Medicine(
    name: 'Antacid',
    pharmacy: 'XYZ Pharmacy',
    stock: 5,
    price: 15,
  ),
];

// Orders (initially empty)
final List<Ma
