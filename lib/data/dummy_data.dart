import 'dart:convert'; // Required for JSON encoding/decoding
import '../models/medicine.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global state variables
List<Medicine> globalMedicines = [];
List<User> users = []; 
List<Order> globalOrders = []; // List to track all orders in real-time
User? currentUser;

// NEW: Order Model to handle Real-time requests
class Order {
  final String orderId;
  final String medicineName;
  final String pharmacyName;
  final String patientEmail;
  String status; // 'Pending', 'Accepted', 'Delivered'

  Order({
    required this.orderId,
    required this.medicineName,
    required this.pharmacyName,
    required this.patientEmail,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'medicineName': medicineName,
    'pharmacyName': pharmacyName,
    'patientEmail': patientEmail,
    'status': status,
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    orderId: map['orderId'],
    medicineName: map['medicineName'],
    pharmacyName: map['pharmacyName'],
    patientEmail: map['patientEmail'],
    status: map['status'],
  );
}

// LOAD DATA from Local Storage (Shared Preferences)
Future<void> loadAllData() async {
  final prefs = await SharedPreferences.getInstance();

  // Load Medicines
  final medData = prefs.getString('med_db');
  if (medData != null) {
    final List decoded = jsonDecode(medData);
    globalMedicines = decoded.map((m) => Medicine.fromMap(m)).toList();
  }

  // Load Orders
  final orderData = prefs.getString('order_db');
  if (orderData != null) {
    final List decoded = jsonDecode(orderData);
    globalOrders = decoded.map((o) => Order.fromMap(o)).toList();
  }

  // Load Users
  final userData = prefs.getString('user_db');
  if (userData != null) {
    final List decoded = jsonDecode(userData);
    users = decoded.map((u) => User.fromMap(u)).toList();
  }
}

// SAVE DATA to Local Storage
Future<void> saveAllData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Save Medicines to 'med_db'
  await prefs.setString('med_db', jsonEncode(globalMedicines.map((m) => m.toMap()).toList()));
  
  // Save Orders to 'order_db'
  await prefs.setString('order_db', jsonEncode(globalOrders.map((o) => o.toMap()).toList()));
  
  // Save Users to 'user_db'
  await prefs.setString('user_db', jsonEncode(users.map((u) => u.toMap()).toList()));
}

// SAVE SESSION for current logged-in user
Future<void> saveCurrentUser(User user) async {
  currentUser = user;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_email', user.email);
  await prefs.setString('current_user_data', jsonEncode(user.toMap()));
}

// LOGOUT: Clears session and returns true for navigation
Future<bool> logoutUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_email');
  await prefs.remove('current_user_data');
  currentUser = null;
  return true; 
}