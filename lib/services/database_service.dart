import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as my_user;
import '../data/dummy_data.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // আপনার User মডেল অনুযায়ী প্যারামিটারগুলো সেট করা হয়েছে
          currentUser = my_user.User(
            name: data['name'] ?? 'User',
            email: data['email'] ?? email,
            password: password, 
            role: data['role'] ?? 'Patient',
            pharmacyName: data['pharmacyName'],
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }
}