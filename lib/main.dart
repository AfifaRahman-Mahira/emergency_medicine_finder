import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const EmergencyMedicineFinder());
}

class EmergencyMedicineFinder extends StatelessWidget {
  const EmergencyMedicineFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Medicine Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}