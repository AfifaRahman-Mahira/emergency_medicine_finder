import 'package:flutter/material.dart';
import '../data/dummy_data.dart';

class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pharmacy Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Medicine Stock', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final med = medicines[index];
                  return Card(
                    child: ListTile(
                      title: Text(med.name),
                      subtitle: Text('${med.pharmacy} - Stock: ${med.stock}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          med.stock += 5;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stock updated')));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
