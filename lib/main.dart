import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home.dart';
import 'screens/pharmacy_home.dart';
import 'data/dummy_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAllData(); 
  
  Widget target;
  if (currentUser == null) {
    target = LoginScreen(); // এখানে const সরানো হয়েছে আপনার এরর অনুযায়ী
  } else {
    if (currentUser!.role == 'Patient') {
      target = PatientHome();
    } else {
      // এই ১৯ নম্বর লাইনেই আপনার 'username' এরর ছিল। 
      // এটাকে এখন pharmacyName অথবা name দিয়ে রিপ্লেস করা হয়েছে।
      target = PharmacyHome(
        pharmacyName: currentUser!.pharmacyName ?? currentUser!.name
      ); 
    }
  }

  runApp(MyApp(startScreen: target));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: SplashScreen(targetScreen: startScreen),
    );
  }
}