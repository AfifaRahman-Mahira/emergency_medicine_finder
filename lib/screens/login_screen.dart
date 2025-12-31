import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'register_screen.dart';
import 'search_screen.dart';
import 'pharmacy_home_screen.dart';
import 'delivery_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void login() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    final user = users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {});

    if (user.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid login')));
      return;
    }

    String role = user['role']!;

    if (role == 'user') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => SearchScreen()));
    } else if (role == 'pharmacy') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => DeliveryHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Emergency Medicine Finder',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Password', border: OutlineInputBorder()),
                ),
                SizedBox(height: 20),
                ElevatedButton(onPressed: login, child: Text('Login')),
                SizedBox(height: 10),
                TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()));
                    },
                    child: Text('Register New Account'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

