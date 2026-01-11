import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Pending Deliveries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // শুধুমাত্র সেই অর্ডারগুলো দেখাবে যেগুলো এখনো ডেলিভারি হয়নি
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No deliveries available right now."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    var data = order.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.directions_bike, color: Colors.white)),
                        title: Text("Medicine: ${data['medicineName']}"),
                        subtitle: Text("From: ${data['pharmacyName']}\nTo: Dhaka (User Location)"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _markAsDelivered(order.id),
                          child: const Text("DELIVER", style: TextStyle(color: Colors.white)),
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

  void _markAsDelivered(String orderId) {
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'delivered'});
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.orangeAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [Text("Earned", style: TextStyle(color: Colors.white)), Text("৳৫০০", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
          Column(children: [Text("Tasks", style: TextStyle(color: Colors.white)), Text("১২", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }
}