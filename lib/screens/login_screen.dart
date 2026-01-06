import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'patient_home.dart';
import 'delivery_home.dart';
import 'pharmacy_home.dart';
import '../data/dummy_data.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'Patient';

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    final matchedUsers = users.where((u) => u.email == email && u.password == password && u.role == role);

    if (matchedUsers.isNotEmpty) {
      Widget page;
      if (role == 'Patient') page = PatientHome();
      else if (role == 'Delivery') page = DeliveryHome();
      else page = PharmacyHome();

      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid user or role!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Login As', border: OutlineInputBorder()),
              items: ['Patient', 'Delivery', 'Pharmacy Owner'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => role = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: login, child: const Text('LOGIN'))),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())), child: const Text('Create Account'))
          ],
        ),
      ),
    );
  }
}