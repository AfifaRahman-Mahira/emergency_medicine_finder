import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pharmacyNameController = TextEditingController();
  String selectedRole = 'Patient';

  void register() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      users.add(User(
        email: emailController.text.trim(),
        password: passwordController.text,
        role: selectedRole,
        pharmacyName: selectedRole == 'Pharmacy' ? pharmacyNameController.text : null,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController, 
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                value: selectedRole,
                items: ['Patient', 'Delivery', 'Pharmacy'].map((String r) {
                  return DropdownMenuItem<String>(
                    value: r,
                    child: Text(r),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue!;
                  });
                },
              ),
              if (selectedRole == 'Pharmacy') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: pharmacyNameController, 
                  decoration: const InputDecoration(labelText: 'Pharmacy Name', border: OutlineInputBorder())
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: register, child: const Text('REGISTER')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}