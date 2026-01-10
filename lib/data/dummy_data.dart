import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = [];
List<Medicine> allMedicines = [];

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
