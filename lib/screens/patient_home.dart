import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/medicine.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  String searchQuery = "";
  String userLocation = "Dhaka"; // ডামি লোকেশন

  @override
  Widget build(BuildContext context) {
    // শুধুমাত্র নির্দিষ্ট লোকেশন এবং সার্চ অনুযায়ী মেডিসিন ফিল্টার
    final filteredMedicines = allMedicines.where((m) => 
      m.location == userLocation && 
      m.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Medicines'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search medicine in $userLocation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: filteredMedicines.isEmpty 
              ? const Center(child: Text("No medicine found in your area!"))
              : ListView.builder(
                  itemCount: filteredMedicines.length,
                  itemBuilder: (context, index) {
                    final med = filteredMedicines[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.medical_services, color: Colors.blue),
                        title: Text(med.name),
                        subtitle: Text("${med.pharmacyName}\nStock: ${med.stock}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("৳${med.price}"),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed: () => showOrderDialog(med),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: med.stock > 0 ? Colors.green : Colors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(med.stock > 0 ? "Order" : "Pre-book", style: const TextStyle(fontSize: 10)),
                            ),
                          ],
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

  void showOrderDialog(Medicine med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(med.stock > 0 ? "Confirm Order" : "Pre-booking"),
        content: Text(med.stock > 0 
          ? "Do you want to order ${med.name} from ${med.pharmacyName}?"
          : "Out of stock! Alternative: ${med.alternative}. Do you want to pre-book?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Action Successful! Notification sent to Pharmacy.")),
              );
            }, 
            child: const Text("Confirm")
          ),
        ],
      ),
    );
  }
}