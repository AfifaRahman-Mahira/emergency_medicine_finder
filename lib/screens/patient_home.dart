import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/medicine.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    // শুধুমাত্র সার্চ করা ওষুধ ফিল্টার হবে
    final filteredMedicines = allMedicines
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Pharmacy Stock')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                labelText: 'Search Medicine (e.g. Napa)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filteredMedicines.isEmpty 
            ? const Center(child: Text('No Medicine Found!'))
            : ListView.builder(
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                final med = filteredMedicines[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${med.pharmacyName} - ৳${med.price}\nLocation: ${med.location}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(med.stock > 0 ? "Order Placed Successfully!" : "Item out of stock! Pre-booked."),
                            backgroundColor: med.stock > 0 ? Colors.green : Colors.orange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: med.stock > 0 ? Colors.blue : Colors.deepOrange),
                      child: Text(med.stock > 0 ? "Order" : "Pre-book"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}