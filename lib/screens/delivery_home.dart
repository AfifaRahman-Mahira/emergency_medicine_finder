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
  String riderCity = ""; 
  double riderRating = 5.0; 

  @override
  void initState() {
    super.initState();
    _fetchRiderData();
  }

  // Database theke Rider-er manually set kora city ebong rating fetch kora
  void _fetchRiderData() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          riderCity = doc.data()?['city'] ?? "";
          riderRating = (doc.data()?['rating'] ?? 5.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error fetching rider data: $e");
    }
  }

  // Rider-er location manually change ba set korar popup logic
  void _showLocationDialog() {
    TextEditingController cityController = TextEditingController(text: riderCity);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Your Delivery City"),
        content: TextField(
          controller: cityController,
          decoration: const InputDecoration(
            hintText: "Enter City Name (e.g. Uttara)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () async {
              if (cityController.text.isNotEmpty) {
                String newCity = cityController.text.trim();
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'city': newCity,
                });
                setState(() => riderCity = newCity);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("SAVE LOCATION", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: const Text('Rider Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange.shade700,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.directions_run), text: "Active Tasks"), 
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildActiveTasksTab(),
            _buildHistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showLocationDialog,
          backgroundColor: Colors.orange.shade700,
          icon: const Icon(Icons.edit_location_alt, color: Colors.white),
          label: const Text("Update Location", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // --- TAB 1: ACTIVE TASKS ---
  Widget _buildActiveTasksTab() {
    return Column(
      children: [
        _buildStatusHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                riderCity.isEmpty ? "No location set" : "Tasks in $riderCity",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: riderCity.isEmpty 
          ? _buildEmptyState("Please click 'Update Location' to start receiving tasks.")
          : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: ['Accepted', 'On the Way'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState("No active tasks found.");
              }

              var availableTasks = snapshot.data!.docs.where((doc) {
                var d = doc.data() as Map<String, dynamic>;
                bool cityMatches = d['city']?.toString().toLowerCase() == riderCity.toLowerCase();
                if (!cityMatches) return false;
                if (d['status'] == 'On the Way') return d['riderId'] == uid;
                return true; 
              }).toList();

              if (availableTasks.isEmpty) return _buildEmptyState("No tasks in $riderCity right now.");

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: availableTasks.length,
                itemBuilder: (context, index) {
                  var doc = availableTasks[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? "Accepted";
                  return _buildOrderCard(doc.id, data, status);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: HISTORY ---
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("No delivery history yet.");

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
              title: Text(data['medicineName'] ?? "Medicine"),
              subtitle: Text("To: ${data['patientName']}"),
              trailing: Text("৳${data['price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: uid)
            .where('status', isEqualTo: 'Delivered')
            .snapshots(),
        builder: (context, snapshot) {
          int completed = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat("Earnings", "৳${completed * 50}"),
              _divider(),
              _headerStat("Completed", "$completed"),
              _divider(),
              _headerStat("Rating", "$riderRating ⭐"),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String id, Map<String, dynamic> data, String status) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: status == "On the Way" ? Colors.blue.shade100 : Colors.orange.shade100,
          child: Icon(status == "On the Way" ? Icons.delivery_dining : Icons.store, color: status == "On the Way" ? Colors.blue : Colors.orange.shade700),
        ),
        title: Text(data['medicineName'] ?? "Order", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Pharmacy: ${data['pharmacyName']}"),
        children: [_buildOrderDetails(id, data, status)],
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
          _buildInfoRow(Icons.payments, "Collect: ৳${data['price']}"),
          const Divider(),
          Row(
            children: [
              _actionBtn(Icons.call, "CALL", Colors.blueGrey, () => _makeCall(data['patientPhone'])),
              const SizedBox(width: 10),
              _actionBtn(Icons.navigation, "MAPS", Colors.green, () => _openMap(data['patientAddress'])),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: status == "Accepted" ? Colors.orange.shade700 : Colors.green),
              onPressed: () => _updateStatus(orderId, status),
              child: Text(status == "Accepted" ? "CONFIRM PICK UP" : "MARK AS DELIVERED", style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String orderId, String currentStatus) async {
    String nextStatus = currentStatus == "Accepted" ? "On the Way" : "Delivered";
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': nextStatus,
      'riderId': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildEmptyState(String msg) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_off, size: 50, color: Colors.grey), const SizedBox(height: 10), Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))])));
  Widget _buildInfoRow(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(i, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(t)]));
  Widget _headerStat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white70)), Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]);
  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);
  Widget _actionBtn(IconData i, String l, Color c, VoidCallback o) => Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: c), onPressed: o, icon: Icon(i, size: 16, color: Colors.white), label: Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))));

  Future<void> _openMap(String? addr) async {
    if (addr == null) return;
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _makeCall(String? p) async {
    if (p == null) return;
    final url = Uri.parse("tel:$p");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Logout?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
        TextButton(onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            // FIXED: const keyword removed here
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
          }
        }, child: const Text("Yes")),
      ],
    ));
  }
}