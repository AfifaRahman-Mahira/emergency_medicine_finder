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

  void login() {
    try {
      final user = users.firstWhere((u) => 
        u.email == emailController.text && 
        u.password == passwordController.text && 
        u.role == selectedRole);

      Widget nextScreen;
      if (user.role == 'Patient') nextScreen = PatientHome();
      else if (user.role == 'Delivery') nextScreen = DeliveryHome();
      else nextScreen = PharmacyHome(pharmacyName: user.pharmacyName ?? "Pharmacy");

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid Credentials or Role!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            DropdownButton<String>(
              value: selectedRole,
              items: ['Patient', 'Delivery', 'Pharmacy'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => selectedRole = val!),
            ),
            ElevatedButton(onPressed: login, child: Text("Login")),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), child: Text("Don't have an account? Register")),
          ],
        ),
      ),
    );
  }
}