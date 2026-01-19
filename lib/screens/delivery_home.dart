import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Rider Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: [
                Icon(Icons.directions_bike, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text("Available Delivery Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Logic: Pharmacy Accept korle Rider dekhte pabe
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', whereIn: ['Accepted', 'On the Way']).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter logic: On the Way thakle sudu oi Rider dekhbe jini pick korechen
                var availableTasks = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  if (d['status'] == 'On the Way') {
                    return d['riderId'] == uid;
                  }
                  return true; 
                }).toList();

                if (availableTasks.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: availableTasks.length,
                  itemBuilder: (context, index) {
                    var doc = availableTasks[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? "Accepted";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: status == "On the Way"
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          child: Icon(
                            status == "On the Way" ? Icons.delivery_dining : Icons.store,
                            color: status == "On the Way" ? Colors.blue : Colors.orange.shade700,
                          ),
                        ),
                        title: Text(data['medicineName'] ?? "Medicine Order",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Pharmacy: ${data['pharmacyName']}"),
                        children: [
                          _buildOrderDetails(doc.id, data, status),
                        ],
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("No active tasks found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(String orderId, Map<String, dynamic> data, String status) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person, "Patient: ${data['patientName']}"),
          _buildInfoRow(Icons.location_on, "Drop-off: ${data['patientAddress']}"),
          _buildInfoRow(Icons.payments, "Collect Cash: ৳${data['price'] ?? '0'}"),
          const Divider(height: 30),
          Row(
            children: [
              _actionButton(
                icon: Icons.call,
                label: "CALL",
                color: Colors.blueGrey,
                onTap: () => _makeCall(data['patientPhone']),
              ),
              const SizedBox(width: 10),
              _actionButton(
                icon: Icons.navigation,
                label: "MAPS",
                color: Colors.green.shade600,
                onTap: () => _openMap(data['patientAddress']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == "Accepted" ? Colors.orange.shade700 : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _updateStatus(orderId, status),
              child: Text(
                status == "Accepted" ? "CONFIRM PICK UP" : "MARK AS DELIVERED",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: uid)
            .where('status', isEqualTo: 'Delivered')
            .snapshots(),
        builder: (context, snapshot) {
          int completed = snapshot.hasData ? snapshot.data!.docs.length : 0;
          int earnings = completed * 50; 

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat("Earnings", "৳$earnings"),
              _divider(),
              _headerStat("Completed", "$completed"),
              _divider(),
              _headerStat("Rating", "5.0 ⭐"),
            ],
          );
        },
      ),
    );
  }

  void _updateStatus(String orderId, String currentStatus) async {
    String nextStatus = currentStatus == "Accepted" ? "On the Way" : "Delivered";
    
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': nextStatus,
      'riderId': uid,
    });
    
    if (nextStatus == "Delivered") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job Complete! Earning added to wallet."), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openMap(String? address) async {
    if (address == null || address.isEmpty) return;
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Go Offline?"),
        content: const Text("You won't see new delivery requests until you log back in."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);

  Widget _headerStat(String label, String value) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );
}