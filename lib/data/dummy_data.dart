import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = [];
List<Medicine> allMedicines = [];

Future<void> saveAllData() async {
  final prefs = await SharedPreferences.getInstance();
  final String userEnc = jsonEncode(users.map((u) => u.toMap()).toList());
  final String medEnc = jsonEncode(allMedicines.map((m) => m.toMap()).toList());
  
  await prefs.setString('user_db', userEnc);
  await prefs.setString('med_db', medEnc);
}

Future<void> loadAllData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? savedUsers = prefs.getString('user_db');
  final String? savedMeds = prefs.getString('med_db');

  if (savedUsers != null) {
    users = List<User>.from(
      (jsonDecode(savedUsers) as List).map((i) => User.fromMap(i))
    );
  }
  if (savedMeds != null) {
    // এখানে টাইপ কাস্টিং নিশ্চিত করা হয়েছে
    allMedicines = List<Medicine>.from(
      (jsonDecode(savedMeds) as List).map((i) => Medicine.fromMap(i))
    );
  }
}