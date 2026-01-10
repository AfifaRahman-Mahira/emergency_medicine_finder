import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/medicine.dart';
import 'login_screen.dart';

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  PharmacyHome({required this.pharmacyName});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final nameCtrl = TextEditingController();
  final genericCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();

  void addMedicine() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

    setState(() {
      allMedicines.add(
        Medicine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(),
          genericName: genericCtrl.text.isEmpty ? "General" : genericCtrl.text.trim(),
          pharmacyName: widget.pharmacyName, // এটি ওনারের ফার্মেসির নাম অটো নিবে
          price: double.tryParse(priceCtrl.text) ?? 0.0,
          stock: int.tryParse(stockCtrl.text) ?? 0,
          location: "Current Location", // এখানে আপনি রিয়েল লোকেশন ডাইনামিক করতে পারেন
          distance: 0.0, // নিজের ফার্মেসির দূরত্ব ০ দেখাবে
        ),
      );
    });
    
    await saveAllData();
    Navigator.pop(context);
    nameCtrl.clear(); genericCtrl.clear(); priceCtrl.clear(); stockCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // লজিক: শুধু এই ফার্মেসির ওষুধগুলো ফিল্টার করো
    final myMeds = allMedicines.where((m) => m.pharmacyName == widget.pharmacyName).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await logoutUser();
              Navigator.pushAndRemoveUntil(
                context, MaterialPageRoute(builder: (_) => LoginScreen()), (_) => false);
            },
          )
        ],
      ),
      body: myMeds.isEmpty 
          ? const Center(child: Text("You haven't added any medicine yet!"))
          : ListView.builder(
              itemCount: myMeds.length,
              itemBuilder: (_, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.medication, color: Colors.white)),
                  title: Text(myMeds[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Generic: ${myMeds[i].genericName}\nStock: ${myMeds[i].stock}"),
                  isThreeLine: true,
                  trailing: Text("${myMeds[i].price} BDT", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Medicine"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Medicine Name")),
              TextField(controller: genericCtrl, decoration: const InputDecoration(labelText: "Generic Name")),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Stock Amount"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: addMedicine, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}