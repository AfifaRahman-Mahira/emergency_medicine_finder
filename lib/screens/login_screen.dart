import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'register_screen.dart';
import 'patient_home.dart';
import 'delivery_home.dart';
import 'pharmacy_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'Patient';

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final user = users.firstWhere((u) =>
          u.email == email &&
          u.password == password &&
          u.role == selectedRole);

      Widget page;
      if (selectedRole == 'Patient') {
        page = PatientHome();
      } else if (selectedRole == 'Delivery') {
        page = DeliveryHome();
      } else {
        page = PharmacyHome(pharmacyName: user.pharmacyName ?? "My Pharmacy");
      }

      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid login or role!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              // এখানে এরর ফিক্স করার জন্য ডিরেক্ট ভ্যালু পাস করছি
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Login As', border: OutlineInputBorder()),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: login, child: const Text('LOGIN')),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Create Account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}