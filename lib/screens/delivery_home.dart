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

  void _showLocationDialog() {
    TextEditingController cityController = TextEditingController(text: riderCity);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Set Your Delivery City", style: TextStyle(fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
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
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text('Rider Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          backgroundColor: const Color(0xFFE65100),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.directions_run), text: "Active Tasks"), 
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
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
          backgroundColor: const Color(0xFFE65100),
          icon: const Icon(Icons.edit_location_alt, color: Colors.white),
          label: const Text("Update Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildActiveTasksTab() {
    return Column(
      children: [
        _buildStatusHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE65100), size: 20),
              const SizedBox(width: 8),
              Text(
                riderCity.isEmpty ? "No location set" : "Tasks in $riderCity",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C)),
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
                  .where('status', whereIn: ['ready_for_pickup', 'shipped'])
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
                  if (d['status'] == 'shipped') return d['riderId'] == uid;
                  return true; 
                }).toList();

                if (availableTasks.isEmpty) return _buildEmptyState("No tasks in $riderCity right now.");

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, left: 10, right: 10),
                  itemCount: availableTasks.length,
                  itemBuilder: (context, index) {
                    var doc = availableTasks[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(doc.id, data);
                  },
                );
              },
            ),
        ),
      ],
    );
  }

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
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check_circle, color: Colors.green)),
                title: Text(data['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("To: ${data['patientName']}"),
                trailing: Text("BDT ${data['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFE65100),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
              _headerStat("Earnings", "BDT ${completed * 50}"),
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

  Widget _buildOrderCard(String id, Map<String, dynamic> data) {
    String status = data['status'] ?? "ready_for_pickup";
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        iconColor: const Color(0xFFE65100),
        leading: CircleAvatar(
          backgroundColor: status == "shipped" ? Colors.blue.shade50 : const Color(0xFFFFF3E0),
          child: Icon(status == "shipped" ? Icons.delivery_dining : Icons.storefront_rounded, 
                     color: status == "shipped" ? Colors.blue : const Color(0xFFE65100)),
        ),
        title: Text(data['medicineName'] ?? "Order", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3E5C))),
        subtitle: Text("Pharmacy: ${data['pharmacyName']}", style: const TextStyle(fontSize: 12)),
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
          _buildInfoRow(Icons.person_outline, "Patient: ${data['patientName']}"),
          _buildInfoRow(Icons.location_on_outlined, "Drop-off: ${data['patientAddress']}"),
          _buildInfoRow(Icons.payments_outlined, "Collect Cash: BDT ${data['price']}"),
          const Divider(height: 25),
          Row(
            children: [
              _actionBtn(Icons.call_rounded, "CALL", Colors.blueGrey.shade700, () => _makeCall(data['patientPhone'])),
              const SizedBox(width: 10),
              _actionBtn(Icons.near_me_rounded, "MAPS", Colors.green.shade700, () => _openMap(data['patientAddress'])),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == "ready_for_pickup" ? const Color(0xFFE65100) : Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () => _updateStatus(orderId, status),
              child: Text(status == "ready_for_pickup" ? "CONFIRM PICK UP" : "MARK AS DELIVERED", 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String orderId, String currentStatus) async {
    String nextStatus = currentStatus == "ready_for_pickup" ? "shipped" : "Delivered";
    
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': nextStatus,
      'riderId': uid,
      'riderName': FirebaseAuth.instance.currentUser?.displayName ?? "Rider",
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(nextStatus == "shipped" ? "Order Picked Up!" : "Order Delivered!"), 
         backgroundColor: Colors.green)
       );
    }
  }

  Widget _buildEmptyState(String msg) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.delivery_dining_outlined, size: 60, color: Colors.grey), const SizedBox(height: 15), Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13))])));
  Widget _buildInfoRow(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(i, size: 18, color: Colors.blueGrey), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: Colors.black87)))]));
  Widget _headerStat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 4), Text(v, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]);
  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);
  Widget _actionBtn(IconData i, String l, Color c, VoidCallback o) => Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: o, icon: Icon(i, size: 18, color: Colors.white), label: Text(l, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))));

  Future<void> _openMap(String? addr) async {
    if (addr == null) return;
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String? p) async {
    if (p == null) return;
    final Uri url = Uri.parse("tel:$p");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Logout?"),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
        TextButton(onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            // FIXED: Removed 'const' keyword to avoid constructor error
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
          }
        }, child: const Text("Yes", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}