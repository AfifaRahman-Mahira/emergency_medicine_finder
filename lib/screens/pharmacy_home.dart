import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/medicine.dart';

class PharmacyHome extends StatefulWidget {
  const PharmacyHome({super.key});
  @override
  _PharmacyHomeState createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  void addNewMedicine() {
    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
      setState(() {
        allMedicines.add(Medicine(
          id: DateTime.now().toString(), // ইউনিক আইডি
          name: nameController.text,
          pharmacyName: "My Shop", 
          location: "Dhaka",
          price: double.parse(priceController.text),
          stock: 50,
        ));
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy - Stock Management')),
      body: ListView.builder(
        itemCount: allMedicines.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.medication),
          title: Text(allMedicines[index].name),
          subtitle: Text("Price: ৳${allMedicines[index].price}"),
          trailing: Text('Stock: ${allMedicines[index].stock}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add New Medicine'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medicine Name')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price')),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: addNewMedicine, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}