import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> with SingleTickerProviderStateMixin {
  String query = "";
  String userCity = "Dhaka";
  String userAddress = "";
  String userName = "User";
  String userPhone = "";

  String? selectedPharmacyId;
  String? selectedPharmacyName;
  Map<String, dynamic>? selectedPharmacyData;

  late TabController _tabController;
  final editNameController = TextEditingController();
  final editAddressController = TextEditingController();
  final editPhoneController = TextEditingController();

  final List<String> bangladeshDistricts = [
    "Dhaka", "Chittagong", "Sylhet", "Rajshahi", "Khulna", "Barisal", "Rangpur", "Mymensingh",
    "Comilla", "Gazipur", "Narayanganj", "Bogra", "Kushtia", "Jessore", "Cox's Bazar", "Brahmanbaria"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPatientProfile();
  }

  void _fetchPatientProfile() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            userName = doc.data()?['name'] ?? "User";
            userAddress = doc.data()?['address'] ?? "";
            userCity = doc.data()?['city'] ?? "Dhaka";
            userPhone = doc.data()?['phone'] ?? "";
            editNameController.text = userName;
            editAddressController.text = userAddress;
            editPhoneController.text = userPhone;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(selectedPharmacyId == null ? "M-Pharma Patient" : selectedPharmacyName!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: selectedPharmacyId != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => selectedPharmacyId = null))
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: _showProfileManager),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "PHARMACIES"),
            Tab(text: "SEARCH ALL"),
            Tab(text: "MY ORDERS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          selectedPharmacyId == null ? _buildPharmacyDirectory() : _buildSpecificPharmacyProfile(),
          _buildAllMedicineSearch(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildPharmacyDirectory() {
    return Column(
      children: [
        _buildCitySelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
                .where('role', isEqualTo: 'Pharmacy')
                .where('city', isEqualTo: userCity)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var pharmacies = snapshot.data!.docs;
              if (pharmacies.isEmpty) return const Center(child: Text("No pharmacies found."));

              return ListView.builder(
                itemCount: pharmacies.length,
                itemBuilder: (context, i) {
                  var data = pharmacies[i].data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.store, color: Colors.white)),
                      title: Text(data['name'] ?? "Unknown Pharmacy", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['address'] ?? "No address"),
                      onTap: () => setState(() {
                        selectedPharmacyId = pharmacies[i].id;
                        selectedPharmacyName = data['name'];
                        selectedPharmacyData = data;
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllMedicineSearch() {
    return Column(
      children: [
        _buildCitySelector(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final meds = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                bool cityMatch = (data['city'] ?? "").toString().toLowerCase() == userCity.toLowerCase();
                bool searchMatch = query.isEmpty || data['name'].toString().toLowerCase().contains(query);
                return cityMatch && searchMatch;
              }).toList();

              return ListView.builder(
                itemCount: meds.length,
                itemBuilder: (context, i) => _buildMedicineCard(meds[i].data() as Map<String, dynamic>),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var orders = snapshot.data!.docs;
        if (orders.isEmpty) return const Center(child: Text("You haven't placed any orders yet."));

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index].data() as Map<String, dynamic>;
            String status = order['status'] ?? "Pending";
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                title: Text("${order['medicineName']} (x${order['quantity'] ?? 1})", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: $status | Bill: BDT ${order['price']}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _orderStepIndicator(status),
                        const SizedBox(height: 15),
                        Text("Pharmacy: ${order['pharmacyName']}"),
                        Text("Payment: ${order['paymentMethod'] ?? 'N/A'}"),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _makeCall(order['pharmacyPhone']),
                          icon: const Icon(Icons.call),
                          label: const Text("Call Pharmacy"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> data) {
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    bool outOfStock = stock <= 0;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(data['name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("BDT ${data['price']} | ${data['pharmacyName']}"),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: outOfStock ? Colors.grey : const Color(0xFF0D47A1)),
          onPressed: outOfStock ? null : () => _showOrderDialog(data),
          child: Text(outOfStock ? "Out" : "ORDER", style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showOrderDialog(Map<String, dynamic> data) {
    int qty = 1;
    String paymentMethod = "Cash on Delivery"; // Default choice
    double unitPrice = double.tryParse(data['price'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Medicine: ${data['name']}"),
              const SizedBox(height: 15),
              const Text("Select Quantity:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setDialogState(() { if(qty > 1) qty--; }), icon: const Icon(Icons.remove_circle_outline)),
                  Text("$qty", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setDialogState(() { qty++; }), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
              const Divider(),
              const Text("Payment Method:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: ["Cash on Delivery", "Online Payment"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setDialogState(() => paymentMethod = val!),
              ),
              const Divider(),
              Text("Total Bill: BDT ${(unitPrice * qty).toStringAsFixed(0)}", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              Text("Delivery City: $userCity", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('orders').add({
                    'patientId': FirebaseAuth.instance.currentUser?.uid,
                    'patientName': userName,
                    'patientPhone': userPhone,
                    'patientAddress': userAddress,
                    'city': userCity, // MANDATORY for Rider tracking
                    'medicineName': data['name'],
                    'quantity': qty,
                    'pharmacyName': data['pharmacyName'],
                    'pharmacyId': data['ownerId'],
                    'pharmacyPhone': data['phone'] ?? "",
                    'price': (unitPrice * qty).toInt(),
                    'paymentMethod': paymentMethod, // Selected Option
                    'status': "Pending",
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _tabController.animateTo(2);
                },
                child: const Text("CONFIRM"))
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificPharmacyProfile() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.white,
          child: Column(
            children: [
              const CircleAvatar(radius: 30, child: Icon(Icons.store, size: 30)),
              Text(selectedPharmacyName ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(selectedPharmacyData?['address'] ?? ""),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => _makeCall(selectedPharmacyData?['phone']), icon: const Icon(Icons.call, color: Colors.green)),
                  const Text("Call Pharmacy"),
                ],
              )
            ],
          ),
        ),
        const Divider(),
        Expanded(child: _buildPharmacyStockList()),
      ],
    );
  }

  Widget _buildCitySelector() => Container(padding: const EdgeInsets.symmetric(horizontal: 15), color: const Color(0xFF0D47A1), child: DropdownButton<String>(isExpanded: true, value: userCity, dropdownColor: const Color(0xFF0D47A1), iconEnabledColor: Colors.white, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), items: bangladeshDistricts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => userCity = v!)));
  Widget _buildSearchBar() => Padding(padding: const EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: InputDecoration(hintText: "Search medicine...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))));
  Widget _buildPharmacyStockList() => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('medicines').where('ownerId', isEqualTo: selectedPharmacyId).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); var meds = snapshot.data!.docs; return ListView.builder(itemCount: meds.length, itemBuilder: (context, i) => _buildMedicineCard(meds[i].data() as Map<String, dynamic>)); });
  void _showProfileManager() { showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Delivery Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Full Name")), TextField(controller: editPhoneController, decoration: const InputDecoration(labelText: "Phone")), TextField(controller: editAddressController, decoration: const InputDecoration(labelText: "Address")), const SizedBox(height: 20), ElevatedButton(onPressed: () { FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'name': editNameController.text, 'phone': editPhoneController.text, 'address': editAddressController.text}); Navigator.pop(context); }, child: const Text("Save Profile"))]))); }
  Color _getStatusColor(String s) => s == "Accepted" ? Colors.blue : s == "On the Way" ? Colors.purple : s == "Delivered" ? Colors.green : Colors.orange;
  IconData _getStatusIcon(String s) => s == "Accepted" ? Icons.check_circle : s == "On the Way" ? Icons.delivery_dining : s == "Delivered" ? Icons.verified : Icons.hourglass_empty;
  Widget _orderStepIndicator(String status) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stepIcon(Icons.shopping_cart, "Ordered", true), _stepLine(status != "Pending"), _stepIcon(Icons.thumb_up, "Pharmacy", status != "Pending"), _stepLine(status == "On the Way" || status == "Delivered"), _stepIcon(Icons.delivery_dining, "Rider", status == "On the Way" || status == "Delivered"), _stepLine(status == "Delivered"), _stepIcon(Icons.done_all, "Received", status == "Delivered")]);
  Widget _stepIcon(IconData icon, String label, bool active) => Column(children: [Icon(icon, color: active ? Colors.green : Colors.grey, size: 20), Text(label, style: TextStyle(fontSize: 8, color: active ? Colors.black : Colors.grey))]);
  Widget _stepLine(bool active) => Container(width: 25, height: 2, color: active ? Colors.green : Colors.grey);
  void _handleLogout() async { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false); }
  Future<void> _makeCall(String? n) async { if (n != null && n.isNotEmpty) { final Uri url = Uri.parse("tel:$n"); if (await canLaunchUrl(url)) await launchUrl(url); } }
}