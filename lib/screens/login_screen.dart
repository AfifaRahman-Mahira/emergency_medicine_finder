import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../data/dummy_data.dart';
import 'register_screen.dart';
import 'search_screen.dart';
import 'pharmacy_home_screen.dart';
import 'delivery_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
=======

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});
>>>>>>> 474f9bb (Initial commit: added login page)

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
<<<<<<< HEAD
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
=======
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Dummy users list
  final List<Map<String, String>> users = [
    {'email': 'test@example.com', 'password': '123456'},
    {'email': 'user@example.com', 'password': 'abcdef'},
  ];
>>>>>>> 474f9bb (Initial commit: added login page)

  void login() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

<<<<<<< HEAD
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
=======
    bool found = users.any(
        (u) => u['email'] == email && u['password'] == password);

    if (found) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful! Welcome $email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
>>>>>>> 474f9bb (Initial commit: added login page)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
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
=======
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
            ],
>>>>>>> 474f9bb (Initial commit: added login page)
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD

=======
>>>>>>> 474f9bb (Initial commit: added login page)
