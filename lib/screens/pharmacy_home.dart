import 'package:flutter/material.dart';
import '../widgets/custom_design.dart';
import '../models/medicine.dart'; // পাথ ঠিক করা হয়েছে
import '../data/dummy_data.dart';

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

  void _addMedicine() {
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;

    setState(() {
      globalMedicines.add(Medicine(
        id: DateTime.now().toString(),
        name: nameController.text,
        generic: genericController.text.isEmpty ? "General" : genericController.text,
        genericName: nameController.text,
        price: double.parse(priceController.text),
        stock: int.parse(stockController.text),
        pharmacyName: widget.pharmacyName,
        location: "Dhaka",
        distance: 0.0,
        alternatives: ["Napa", "Ace"],
      ));
    });
    
    nameController.clear();
    priceController.clear();
    stockController.clear();
    genericController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final myMedicines = globalMedicines.where((m) => m.pharmacyName == widget.pharmacyName).toList();

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
          Expanded(
            child: ListView.builder(
              itemCount: myMedicines.length,
              itemBuilder: (context, index) {
                final med = myMedicines[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    title: Text(med.name),
                    subtitle: Text("৳${med.price} | Stock: ${med.stock}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => med.stock--)),
                        Text("${med.stock}"),
                        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => med.stock++)),
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