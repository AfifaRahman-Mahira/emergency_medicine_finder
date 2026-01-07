import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(EmergencyMedicineFinder());
}

class EmergencyMedicineFinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Medicine Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // এখানে const থাকলে সরাইয়া দিবি
    );
  }
}