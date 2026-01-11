import '../models/medicine.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
List<Medicine> globalMedicines = [];
List<User> users = []; 
User? currentUser;

Future<void> loadAllData() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

Future<void> saveAllData() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

Future<void> saveCurrentUser(User user) async {
  currentUser = user;
  final prefs = await SharedPreferences.getInstance();
  // save user email
  await prefs.setString('user_email', user.email);
}