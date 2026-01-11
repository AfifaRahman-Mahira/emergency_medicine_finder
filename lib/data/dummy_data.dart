import '../models/medicine.dart';
import '../models/user.dart';

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
  await Future.delayed(const Duration(milliseconds: 100));
}