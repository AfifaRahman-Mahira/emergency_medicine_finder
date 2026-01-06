import '../models/user.dart';
import '../models/medicine.dart';

List<User> users = []; 

List<Medicine> allMedicines = [
  Medicine(
    id: '1', 
    name: 'Napa Extend', 
    pharmacyName: 'City Pharma', 
    location: 'Dhaka', 
    stock: 50, 
    price: 20.0,
  ),
  Medicine(
    id: '2', 
    name: 'Ace Plus', 
    pharmacyName: 'Lazz Pharma', 
    location: 'Dhaka', 
    stock: 0, 
    price: 15.0,
  ),
];