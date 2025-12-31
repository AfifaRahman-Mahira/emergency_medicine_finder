import 'package:flutter/material.dart';
import '../models/user.dart';
import '../data/dummy_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  UserType selectedType = UserType.patient;

  void register() {
    String email = emailController.text.trim();
    String pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fill all fields')));
      return;
    }

    users.add(User(email: email, password: pass, type: selectedType));

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Account created!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 10),
            DropdownButton<UserType>(
              value: selectedType,
              items: UserType.values.map((e) {
                return DropdownMenuItem<UserType>(
                  value: e,
                  child: Text(e.toString().split('.').last),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
