import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'patient_home.dart';
import 'delivery_home.dart';
import 'pharmacy_home.dart';
import '../widgets/custom_design.dart';
import '../data/dummy_data.dart'; 
import '../models/user.dart' as my_user;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String _selectedRole = 'Patient'; 
  bool isLoading = false;

  // Handles the user authentication process
  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"))
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Authenticate with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Fetch user details from Firestore 'users' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String dbRole = userData['role'];

        // 3. Role validation check
        // dbRole 'Rider' holeo jate 'Rider' selection-e login hoy seta ensure kora hoyeche
        if (dbRole != _selectedRole) {
          throw FirebaseAuthException(
            code: 'wrong-role', 
            message: "Role mismatch! You are registered as $dbRole"
          );
        }

        // 4. Map global currentUser data for session management
        currentUser = my_user.User(
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          password: passwordController.text.trim(),
          role: dbRole,
          pharmacyName: userData['pharmacyName'],
        );

        // 5. Determine destination screen based on role
        Widget next;
        if (dbRole == 'Patient') {
          next = const PatientHome(); 
        } else if (dbRole == 'Rider') {
          
          next = const DeliveryHome(); 
        } else {
          // Pharmacy role- PharmacyHome
          String pName = userData['pharmacyName'] ?? userData['name'] ?? "My Pharmacy";
          next = PharmacyHome(pharmacyName: pName);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => next)
          );
        }
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found', 
          message: "User data not found in database"
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? "Login Failed"),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Header Image/Logo Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.1), 
                        blurRadius: 20
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_liquid_rounded, 
                    size: 60, 
                    color: Colors.blueAccent
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Welcome Back", 
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1A237E)
                )
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: emailController, 
                label: "Email Address", 
                icon: Icons.alternate_email_rounded
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: passwordController, 
                label: "Password", 
                icon: Icons.lock_outline_rounded, 
                isPassword: true
              ),
              const SizedBox(height: 20),
              const Text(
                "Login As", 
                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              
              // Role Selection Dropdown 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.2)
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
               
                    items: ['Patient', 'Pharmacy', 'Rider'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value, 
                        child: Text(value)
                      );
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedRole = newValue!),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button with Loading Indicator
              isLoading 
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(text: "LOGIN", onPressed: login),
              const SizedBox(height: 25),
              
              // Navigation to Register Screen
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const RegisterScreen())
                  ),
                  child: const Text(
                    "Register Now", 
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}