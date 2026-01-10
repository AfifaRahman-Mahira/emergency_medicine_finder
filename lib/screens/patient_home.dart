import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'login_screen.dart';

class PatientHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await logoutUser();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (_) => false,
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: allMedicines.length,
        itemBuilder: (context, index) {
          final med = allMedicines[index];
          return ListTile(
            title: Text(med.name),
            subtitle: Text(med.pharmacyName),
            trailing: Text("${med.price} BDT"),
          );
        },
      ),
    );
  }
}
