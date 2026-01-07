import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = []; 

List<Medicine> allMedicines = [
  Medicine(
    id: '1',
    name: 'Napa Extend',
    pharmacyName: 'City Pharma',
    location: 'Dhaka',
    price: 20,
    stock: 50,
  ),
];

Future<void> saveAllData() async {
  // Logic to save data (e.g., SharedPreferences)
}