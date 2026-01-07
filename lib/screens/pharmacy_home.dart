import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/medicine.dart';

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  PharmacyHome({required this.pharmacyName});

  @override
  _PharmacyHomeState createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  void addMedicine() async {
    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
      setState(() {
        allMedicines.add(Medicine(
          id: DateTime.now().toString(),
          name: nameController.text,
          pharmacyName: widget.pharmacyName,
          price: double.parse(priceController.text),
        ));
      });
      await saveAllData(); // ডাটা ফাইলে সেভ হবে
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pharmacyName)),
      body: ListView.builder(
        itemCount: allMedicines.where((m) => m.pharmacyName == widget.pharmacyName).length,
        itemBuilder: (context, index) {
          final med = allMedicines.where((m) => m.pharmacyName == widget.pharmacyName).toList()[index];
          return ListTile(title: Text(med.name), trailing: Text("${med.price} BDT"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add New Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Medicine Name")),
            TextField(controller: priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [ElevatedButton(onPressed: addMedicine, child: Text("Add"))],
      ),
    );
  }
}