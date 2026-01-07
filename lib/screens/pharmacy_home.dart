import 'package:flutter/material.dart';
import '../data/dummy_data.dart'; // ইম্পোর্ট মাস্ট

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  const PharmacyHome({super.key, required this.pharmacyName});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pharmacyName)),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await saveAllData(); // সরাসরি কল
          },
          child: const Text("Save Pharmacy Data"),
        ),
      ),
    );
  }
}