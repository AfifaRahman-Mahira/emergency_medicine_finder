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
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  void addMedicine() async {
    allMedicines.add(
      Medicine(
        id: DateTime.now().toString(),
        name: nameController.text,
        pharmacyName: widget.pharmacyName,
        price: double.parse(priceController.text),
      ),
    );
    await saveAllData();
    Navigator.pop(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final meds = allMedicines
        .where((m) => m.pharmacyName == widget.pharmacyName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
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
        itemCount: meds.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(meds[i].name),
          trailing: Text("${meds[i].price} BDT"),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Add Medicine"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: addMedicine, child: const Text("Add"))
            ],
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
