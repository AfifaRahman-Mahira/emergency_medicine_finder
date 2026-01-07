import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'data/dummy_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAllData(); // load data on app start
  runApp(EmergencyMedicineFinder());
}


class EmergencyMedicineFinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emergency Medicine Finder',
      home: LoginScreen(),
    );
  }
}