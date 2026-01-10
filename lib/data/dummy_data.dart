import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = [];
List<Medicine> allMedicines = [];
User? currentUser;


void initializeDummyMedicines() {
  if (allMedicines.isEmpty) {
    allMedicines = [

      Medicine(
        id: '1',
        name: "Ace 500",
        genericName: "Paracetamol",
        pharmacyName: "Lazz Pharma",
        price: 10.0,
        stock: 50,
        location: "Dhanmondi, Dhaka",
        distance: 1.2,
      ),
    ];
  }
}


Future<void> saveAllData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_db', jsonEncode(users.map((u) => u.toMap()).toList()));
  await prefs.setString('med_db', jsonEncode(allMedicines.map((m) => m.toMap()).toList()));
}


Future<void> loadAllData() async {
  final prefs = await SharedPreferences.getInstance();
  
  final savedUsers = prefs.getString('user_db');
  final savedMeds = prefs.getString('med_db');
  final sessionData = prefs.getString('current_user');

  if (savedUsers != null) {
    users = (jsonDecode(savedUsers) as List).map((e) => User.fromMap(e)).toList();
  }
  
  if (savedMeds != null) {
    allMedicines = (jsonDecode(savedMeds) as List).map((e) => Medicine.fromMap(e)).toList();
  } else {
    
    initializeDummyMedicines();
    await saveAllData();
  }

  if (sessionData != null) {
    currentUser = User.fromMap(jsonDecode(sessionData));
  }
}

Future<void> saveCurrentUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(user.toMap()));
  currentUser = user;
}

Future<void> logoutUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_user');
  currentUser = null;
}