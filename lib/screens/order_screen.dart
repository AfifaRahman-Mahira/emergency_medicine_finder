import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../data/dummy_data.dart';

class OrderScreen extends StatelessWidget {
  final Medicine medicine;

  const OrderScreen({super.key, required this.medicine});

  void placeOrder(BuildContext context) {
    orders.add({
      'medicine': medicine,
      'patient': 'Demo Patient',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Medicine')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medicine: ${medicine.name}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Pharmacy: ${medicine.pharmacy}'),
            SizedBox(height: 10),
            Text('Stock: ${medicine.stock}'),
            SizedBox(height: 10),
            if (medicine.stock == 0 && medicine.alternative != null)
              Text('Alternative: ${medicine.alternative}',
                  style: TextStyle(color: Colors.green)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => placeOrder(context),
              child: Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
