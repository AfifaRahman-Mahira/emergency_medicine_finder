import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_design.dart'; 

class RegisterScreen extends StatefulWidget {
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
  bool isLoading = false;

  void register() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': nameController.text.isEmpty ? emailController.text.split('@')[0] : nameController.text,
        'email': emailController.text.trim(),
        'role': selectedRole,
        'createdAt': DateTime.now(),
      };

      if (selectedRole == 'Pharmacy') {
        userData['pharmacyName'] = pharmacyController.text.trim();
        
        await FirebaseFirestore.instance.collection('pharmacies').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': pharmacyController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'rating': 5.0,
          'isVerified': true,
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Successful!")));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error occurred")));
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
              const Text("Create Account", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 30),
              CustomTextField(controller: nameController, label: "Full Name", icon: Icons.person_outline_rounded),
              CustomTextField(controller: emailController, label: "Email Address", icon: Icons.alternate_email_rounded),
              CustomTextField(controller: passwordController, label: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
              const SizedBox(height: 20),
              const Text("  Register As", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ['Patient', 'Delivery', 'Pharmacy'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
              ),
              if (selectedRole == 'Pharmacy') ...[
                const SizedBox(height: 15),
                CustomTextField(controller: pharmacyController, label: "Pharmacy Name", icon: Icons.local_pharmacy_rounded),
                CustomTextField(controller: phoneController, label: "Contact Number", icon: Icons.phone),
                CustomTextField(controller: addressController, label: "Pharmacy Address", icon: Icons.location_on),
              ],
              const SizedBox(height: 40),
              isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : CustomButton(text: "REGISTER", onPressed: register),
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}