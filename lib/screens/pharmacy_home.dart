import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ফায়ারবেস ইমপোর্ট
import '../widgets/custom_design.dart';
import '../models/medicine.dart';

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  const PharmacyHome({super.key, required this.pharmacyName});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();

  // ডাটাবেসে ঔষধ সেভ করার ফাংশন
  void _addMedicine() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('medicines').add({
        'name': nameController.text.trim(),
        'generic': genericController.text.isEmpty ? "General" : genericController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0.0,
        'stock': int.tryParse(stockController.text) ?? 0,
        'pharmacyName': widget.pharmacyName,
        'location': "Dhaka",
        'timestamp': FieldValue.serverTimestamp(), // সময় রেকর্ড রাখা
      });

      nameController.clear();
      priceController.clear();
      stockController.clear();
      genericController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        backgroundColor: Colors.blueAccent,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context))],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: () => _showAddSheet(), child: const Text("Add New")),
              ],
            ),
          ),
          // রিয়েল-টাইম ডাটা দেখানোর জন্য StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .where('pharmacyName', isEqualTo: widget.pharmacyName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final meds = snapshot.data!.docs;

                if (meds.isEmpty) return const Center(child: Text("No medicines added yet."));

                return ListView.builder(
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    var data = meds[index].data() as Map<String, dynamic>;
                    var docId = meds[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text("৳${data['price']} | Stock: ${data['stock']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                if (data['stock'] > 0) {
                                  FirebaseFirestore.instance.collection('medicines').doc(docId).update({'stock': data['stock'] - 1});
                                }
                              },
                            ),
                            Text("${data['stock']}"),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('medicines').doc(docId).update({'stock': data['stock'] + 1});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... বাকি _showAddSheet এবং _buildHeader কোড একই থাকবে ...
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: nameController, label: "Medicine Name", icon: Icons.medication),
            CustomTextField(controller: genericController, label: "Generic Name", icon: Icons.science),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: priceController, label: "Price", icon: Icons.attach_money)),
                const SizedBox(width: 10),
                Expanded(child: CustomTextField(controller: stockController, label: "Stock", icon: Icons.inventory)),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(text: "SAVE", onPressed: _addMedicine),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blueAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [Icon(Icons.star, color: Colors.white), Text("4.5", style: TextStyle(color: Colors.white))]),
          Column(children: [Icon(Icons.location_on, color: Colors.white), Text("Dhaka", style: TextStyle(color: Colors.white))]),
        ],
      ),
    );
  }
}