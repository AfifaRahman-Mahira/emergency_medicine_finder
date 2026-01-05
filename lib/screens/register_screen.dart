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
  UserType type = UserType.patient;

  void register() {
    users.add(User(
      email: emailController.text,
      password: passwordController.text,
      type: type,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
            DropdownButton<UserType>(
              value: type,
              items: UserType.values.map((e) =>
                DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            ElevatedButton(onPressed: register, child: const Text('Register'))
          ],
        ),
      ),
    );
  }
}
