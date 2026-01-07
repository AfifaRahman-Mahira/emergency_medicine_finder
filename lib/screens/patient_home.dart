import 'package:flutter/material.dart';
import '../data/dummy_data.dart'; // এই ইমপোর্টটি জরুরি

class PatientHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patient Dashboard")),
      body: allMedicines.isEmpty 
        ? Center(child: Text("No medicine found!"))
        : ListView.builder(
            itemCount: allMedicines.length,
            itemBuilder: (context, index) {
              final med = allMedicines[index];
              return ListTile(
                title: Text(med.name),
                subtitle: Text("Pharmacy: ${med.pharmacyName}"),
                trailing: Text("${med.price} BDT"),
              );
            },
          ),
    );
  }
}