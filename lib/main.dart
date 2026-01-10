import 'package:flutter/material.dart';
import 'data/dummy_data.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home.dart';
import 'screens/pharmacy_home.dart';
import 'screens/delivery_home.dart';
import 'screens/splash_screen.dart'; // নতুন ইমপোর্ট

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // আপনার আগের ডাটা লোড করার লজিক (অপরিবর্তিত)
  await loadAllData();
  await loadCurrentUser();

  runApp(EmergencyMedicineFinder());
}

class EmergencyMedicineFinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // লজিক অনুযায়ী আমরা ঠিক করছি স্প্ল্যাশ স্ক্রিনের পর কোন পেজে যাবে
    Widget nextScreen;

    if (currentUser == null) {
      nextScreen = LoginScreen();
    } else if (currentUser!.role == 'Patient') {
      nextScreen = PatientHome();
    } else if (currentUser!.role == 'Delivery') {
      nextScreen = DeliveryHome();
    } else {
      nextScreen = PharmacyHome(
        pharmacyName: currentUser!.pharmacyName ?? 'Pharmacy',
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emergency Medicine Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        useMaterial3: true,
      ),
      // এখানে home-এ আমরা SplashScreen দিয়েছি এবং তাতে nextScreen পাঠিয়ে দিচ্ছি
      home: SplashScreen(targetScreen: nextScreen),
    );
  }
}