import 'package:flutter/material.dart';
import '../data/dummy_data.dart';

class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: orders.isEmpty
            ? Center(child: Text('No deliveries assigned'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    child: ListTile(
                      title: Text(order['medicine'].name),
                      subtitle: Text('Patient: ${order['patient']}'),
                      trailing: ElevatedButton(
                        child: Text('Delivered'),
                        onPressed: () {
                          orders.removeAt(index);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
