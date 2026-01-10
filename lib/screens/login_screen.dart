import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'register_screen.dart';
import 'patient_home.dart';
import 'delivery_home.dart';
import 'pharmacy_home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'Patient';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await loadAllData(); // 🔥 VERY IMPORTANT
    setState(() {
      loading = false;
    });
  }

  void login() {
    try {
      final user = users.firstWhere((u) =>
          u.email == emailController.text.trim() &&
          u.password == passwordController.text.trim() &&
          u.role == selectedRole);

      Widget next;
      if (user.role == 'Patient') {
        next = PatientHome();
      } else if (user.role == 'Delivery') {
        next = DeliveryHome();
      } else {
        next = PharmacyHome(
          pharmacyName: user.pharmacyName ?? 'Pharmacy',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email / password / role")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: selectedRole,
              items: ['Patient', 'Delivery', 'Pharmacy']
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => selectedRole = val!),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: login, child: const Text("Login")),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              ),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
