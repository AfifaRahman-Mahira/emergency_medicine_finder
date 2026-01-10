import 'package:flutter/material.dart';
import '../models/user.dart';
import '../data/dummy_data.dart';
import '../widgets/custom_design.dart'; // ডিজাইন ফাইল ইমপোর্ট

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pharmacyController = TextEditingController();
  String selectedRole = 'Patient';

  void register() async {
    // আপনার অরিজিনাল লজিক
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all fields"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    users.add(
      User(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: selectedRole,
        pharmacyName:
            selectedRole == 'Pharmacy' ? pharmacyController.text.trim() : null,
      ),
    );

    await saveAllData(); // ডাটা সেভ করা

    if (mounted) {
      Navigator.pop(context); // সাকসেস হলে আগের পেজে ফেরত যাওয়া
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Join us to find emergency medicines easily",
                style: TextStyle(fontSize: 15, color: Colors.blueGrey),
              ),
              const SizedBox(height: 40),

              // এনিমেটেড ইমেইল ফিল্ড
              CustomTextField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 15),

              // এনিমেটেড পাসওয়ার্ড ফিল্ড
              CustomTextField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // রোল সিলেকশন ড্রপডাউন
              const Text("  Register As",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.blueAccent),
                    items: ['Patient', 'Delivery', 'Pharmacy']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRole = v!),
                  ),
                ),
              ),

              // ফার্মেসি নেম ফিল্ড (লজিক অনুযায়ী শুধু ফার্মেসি সিলেক্ট করলে আসবে)
              if (selectedRole == 'Pharmacy') ...[
                const SizedBox(height: 20),
                CustomTextField(
                  controller: pharmacyController,
                  label: "Pharmacy Name",
                  icon: Icons.local_pharmacy_rounded,
                ),
              ],

              const SizedBox(height: 40),

              // আপনার তৈরি করা প্রিমিয়াম বাটন
              CustomButton(
                text: "REGISTER",
                onPressed: register,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}