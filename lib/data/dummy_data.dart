import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = [];
List<Medicine> allMedicines = [];
User? currentUser;

// Save all users and medicines
Future<void> saveAllData() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'user_db',
    jsonEncode(users.map((u) => u.toMap()).toList()),
  );

  await prefs.setString(
    'med_db',
    jsonEncode(allMedicines.map((m) => m.toMap()).toList()),
  );
}

// Load all users and medicines
Future<void> loadAllData() async {
  final prefs = await SharedPreferences.getInstance();

  final savedUsers = prefs.getString('user_db');
  final savedMeds = prefs.getString('med_db');

  if (savedUsers != null) {
    users = (jsonDecode(savedUsers) as List)
        .map((e) => User.fromMap(e))
        .toList();
  }

  if (savedMeds != null) {
    allMedicines = (jsonDecode(savedMeds) as List)
        .map((e) => Medicine.fromMap(e))
        .toList();
  }
}

// Save logged-in user
Future<void> saveCurrentUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(user.toMap()));
  currentUser = user;
}

// Load logged-in user
Future<void> loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('current_user');
  if (data != null) {
    currentUser = User.fromMap(jsonDecode(data));
  }
}

// Logout user
Future<void> logoutUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_user');
  currentUser = null;
}
