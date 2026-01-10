import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget targetScreen; // কোন পেজে যাবে তা এখান থেকে রিসিভ করবে

  const SplashScreen({super.key, required this.targetScreen});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ৩ সেকেন্ড পর অটোমেটিক নেভিগেশন
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.targetScreen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // প্রিমিয়াম লোগো অ্যানিমেশন
                TweenAnimationBuilder(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: const Icon(Icons.medication_liquid_rounded, 
                      size: 100, color: Colors.blueAccent),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Medicine Finder",
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1A237E),
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ],
            ),
          ),
          // নিচের দিকে ছোট একটি টেক্সট
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text("Your Health, Our Priority", 
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }
}