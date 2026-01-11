import 'package:flutter/material.dart';
import '../models/user.dart';
import '../data/dummy_data.dart';
import '../widgets/custom_design.dart'; 

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pharmacyController = TextEditingController();
  String selectedRole = 'Patient';

  void register() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    users.add(
      User(
        name: emailController.text.split('@')[0], 
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: selectedRole,
        pharmacyName: selectedRole == 'Pharmacy' ? pharmacyController.text.trim() : null,
      ),
    );

    await saveAllData(); 
    if (mounted) Navigator.pop(context); 
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
              const SizedBox(height: 40),
              CustomTextField(controller: emailController, label: "Email Address", icon: Icons.alternate_email_rounded),
              const SizedBox(height: 15),
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
                const SizedBox(height: 20),
                CustomTextField(controller: pharmacyController, label: "Pharmacy Name", icon: Icons.local_pharmacy_rounded),
              ],
              const SizedBox(height: 40),
              CustomButton(text: "REGISTER", onPressed: register),
            ],
          ),
        ),
      ),
    );
  }
}