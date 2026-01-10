import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  const MedicineCard({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    bool outOfStock = medicine.stock == 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medicine.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(medicine.genericName, style: TextStyle(color: Colors.blue.withValues(alpha: 0.6))),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${medicine.distance} km away", style: const TextStyle(color: Colors.grey)),
                Text("${medicine.price} BDT", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(outOfStock ? "Out of Stock" : "Stock: ${medicine.stock}", 
                     style: TextStyle(color: outOfStock ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {}, 
                  style: ElevatedButton.styleFrom(backgroundColor: outOfStock ? Colors.orange : Colors.blue),
                  child: Text(outOfStock ? "Pre-book" : "Order Now", style: const TextStyle(color: Colors.white))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}