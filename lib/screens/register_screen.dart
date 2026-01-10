import 'package:flutter/material.dart';
import '../models/user.dart';
import '../data/dummy_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pharmacyController = TextEditingController();
  String selectedRole = 'Patient';

  void register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!")),
      );
      return;
    }

    users.add(User(
      email: email,
      password: password,
      role: selectedRole,
      pharmacyName: selectedRole == 'Pharmacy' ? pharmacyController.text.trim() : null,
    ));


    await saveAllData(); 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful! Now Login.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 16),
             
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Register As", border: OutlineInputBorder()),
                initialValue: selectedRole, 
                items: ['Patient', 'Delivery', 'Pharmacy'].map((String r) {
                  return DropdownMenuItem<String>(value: r, child: Text(r));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedRole = val!;
                  });
                },
              ),
              if (selectedRole == 'Pharmacy') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: pharmacyController,
                  decoration: const InputDecoration(labelText: "Pharmacy Name", border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: register, 
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text("REGISTER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}