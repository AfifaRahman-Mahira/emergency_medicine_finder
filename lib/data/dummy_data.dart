import '../models/medicine.dart';

<<<<<<< HEAD
// Users stored as List of Map (dynamic registration)
List<Map<String, String>> users = [];

// Medicine list
List<Medicine> medicines = [
  Medicine(name: 'Paracetamol', pharmacy: 'ABC Pharmacy', stock: 10, alternative: 'Napa'),
  Medicine(name: 'Antacid', pharmacy: 'XYZ Pharmacy', stock: 0, alternative: 'Gastril'),
];

// Orders
List<Map<String, dynamic>> orders = [];





=======
List<Map<String, String>> dummyUsers = [
  {"email": "user@gmail.com", "password": "1234", "role": "user"},
  {"email": "pharmacy@gmail.com", "password": "1234", "role": "pharmacy"},
  {"email": "delivery@gmail.com", "password": "1234", "role": "delivery"},
];

List<Medicine> medicines = [
  Medicine(
    name: 'Paracetamol',
    pharmacy: 'ABC Pharmacy',
    stock: 10,
    alternative: 'Napa',
  ),
  Medicine(
    name: 'Antacid',
    pharmacy: 'XYZ Pharmacy',
    stock: 0,
    alternative: 'Gastril',
  ),
];

List<Map<String, dynamic>> orders = [];
>>>>>>> 474f9bb (Initial commit: added login page)
