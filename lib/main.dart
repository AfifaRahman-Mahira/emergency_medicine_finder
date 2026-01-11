import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home.dart';
import 'screens/pharmacy_home.dart';
import 'data/dummy_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await loadAllData(); 
  
  Widget target;
  if (currentUser == null) {
    // এখানে 'const' সরিয়ে দেওয়া হয়েছে
    target = LoginScreen(); 
  } else {
    if (currentUser!.role == 'Patient') {
      // এখানেও 'const' সরিয়ে দেওয়া হয়েছে
      target = PatientHome();
    } else {
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
      title: 'Emergency Medicine Finder',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00B0FF),
          error: const Color(0xFFD32F2F),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: SplashScreen(targetScreen: startScreen),
    );
  }
}