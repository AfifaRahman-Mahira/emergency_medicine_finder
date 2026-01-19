import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_design.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController(); 
  final pharmacyController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController(); 
  
  String selectedRole = 'Patient';
  String? selectedRegCity = 'Dhaka'; // Default city set to Dhaka
  bool isLoading = false;

  // Function to register user in Firebase Auth and Firestore
  void register() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Prepare common user data structure
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': nameController.text.isEmpty ? emailController.text.split('@')[0] : nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'city': selectedRegCity, // Critical for location-based medicine filtering
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Firestore server-side timestamp
      };

      // 3. Handle Pharmacy-specific data requirements
      if (selectedRole == 'Pharmacy') {
        userData['pharmacyName'] = pharmacyController.text.trim();
        
        // Save to a specialized collection to help patients discover nearby pharmacies
        await FirebaseFirestore.instance.collection('pharmacies').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'pharmacyName': pharmacyController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'city': selectedRegCity,
          'rating': 5.0,
          'isVerified': true,
        });
      }

      // 4. Save the full profile to the main users collection
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Return to login screen
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error occurred"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", 
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const Text("Join our emergency network", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              
              CustomTextField(controller: nameController, label: "Full Name", icon: Icons.person_outline_rounded),
              CustomTextField(controller: emailController, label: "Email Address", icon: Icons.alternate_email_rounded),
              CustomTextField(controller: passwordController, label: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
              
              const SizedBox(height: 20),
              const Text("   Register As", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              
              // Role Selection UI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    // Fixed: withOpacity replaced with withValues
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                  ]
                ),
                child: DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ['Patient', 'Pharmacy'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
              ),

              const SizedBox(height: 15),
              // City Selection UI
              const Text("   Select Your City", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    // Fixed: withOpacity replaced with withValues
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                  ]
                ),
                child: DropdownButton<String>(
                  value: selectedRegCity,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna', 'Barisal']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => selectedRegCity = v),
                ),
              ),

              // Dynamic fields based on role selection
              if (selectedRole == 'Pharmacy') ...[
                const SizedBox(height: 15),
                CustomTextField(controller: pharmacyController, label: "Pharmacy Name", icon: Icons.local_pharmacy_rounded),
                CustomTextField(controller: phoneController, label: "Pharmacy Phone", icon: Icons.phone),
                CustomTextField(controller: addressController, label: "Detailed Address", icon: Icons.location_on),
              ] else ...[
                const SizedBox(height: 15),
                CustomTextField(controller: phoneController, label: "Personal Phone", icon: Icons.phone),
                CustomTextField(controller: addressController, label: "Your Area/Address", icon: Icons.home),
              ],

              const SizedBox(height: 40),
              // Registration button state management
              isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : CustomButton(text: "CREATE ACCOUNT", onPressed: register),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}