import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'register_screen.dart';
import 'patient_home.dart';
import 'delivery_home.dart';
import 'pharmacy_home.dart';
import '../widgets/custom_design.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'Patient';

  void login() async {
    try {
      final user = users.firstWhere(
        (u) =>
            u.email == emailController.text.trim() &&
            u.password == passwordController.text.trim() &&
            u.role == selectedRole,
      );

      await saveCurrentUser(user);

      Widget next;
      if (user.role == 'Patient') {
        next = PatientHome();
      } else if (user.role == 'Delivery') {
        next = DeliveryHome();
      } else {
        next = PharmacyHome(
          pharmacyName: user.pharmacyName ?? user.name,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => next));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid email / password / role"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), 
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: Colors.blueAccent.withValues(alpha: 0.05)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: TweenAnimationBuilder(
                      duration: const Duration(seconds: 1),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(scale: value, child: child),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.medication_liquid_rounded, size: 60, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  const SizedBox(height: 8),
                  const Text("Sign in to your account", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                  const SizedBox(height: 40),

                  CustomTextField(controller: emailController, label: "Email Address", icon: Icons.alternate_email_rounded),
                  const SizedBox(height: 20),
                  CustomTextField(controller: passwordController, label: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
                  const SizedBox(height: 25),

                  const Text("  Login As", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
                        items: ['Patient', 'Delivery', 'Pharmacy']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(text: "LOGIN", onPressed: login),
                  const SizedBox(height: 25),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                      child: const Text("Register Now", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}