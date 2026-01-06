import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String role = 'Patient';

  void register() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      users.add(User(
        email: emailController.text.trim(),
        password: passwordController.text,
        role: role,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered successfully as $role')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
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
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: ['Patient', 'Delivery', 'Pharmacy Owner']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => role = val!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: register, child: const Text('REGISTER')),
          ],
        ),
      ),
    );
  }
}