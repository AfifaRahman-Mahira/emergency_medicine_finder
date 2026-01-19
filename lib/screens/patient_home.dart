import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart'; // Ensure this file exists

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

  // --- TAB 1: PHARMACY DIRECTORY ---
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
              if (pharmacies.isEmpty) return const Center(child: Text("No pharmacies found in this city.", style: TextStyle(color: Colors.black54)));

              return ListView.builder(
                itemCount: pharmacies.length,
                itemBuilder: (context, i) {
                  var data = pharmacies[i].data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.store, color: Colors.white)),
                      title: Text(data['name'] ?? "Unknown Pharmacy", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      subtitle: const Text("Tap to view available stock", style: TextStyle(color: Colors.black54)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
                      onTap: () => setState(() {
                        selectedPharmacyId = pharmacies[i].id;
                        selectedPharmacyName = data['name'];
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

  // --- TAB 2: GLOBAL SEARCH ---
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

              if (meds.isEmpty) return const Center(child: Text("No medicines found.", style: TextStyle(color: Colors.black54)));

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

  // --- TAB 3: ORDER TRACKER ---
  Widget _buildOrdersTab() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('patientId', isEqualTo: uid)
          .orderBy('timestamp', descending: true) // Added sorting
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("You haven't placed any orders yet.", style: TextStyle(color: Colors.black54)));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String status = order['status'] ?? "Pending";
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 3,
              child: ExpansionTile(
                leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                title: Text(order['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                subtitle: Text("Status: $status", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w500)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _orderStepIndicator(status),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Pharmacy: ${order['pharmacyName']}", style: const TextStyle(color: Colors.black87)),
                            Text("Bill: ৳${order['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                          onPressed: () => _makeCall(order['pharmacyPhone']),
                          icon: const Icon(Icons.call, color: Colors.white, size: 18),
                          label: const Text("Call Pharmacy", style: TextStyle(color: Colors.white)),
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                Text("৳${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.store, size: 14, color: Colors.blue),
                const SizedBox(width: 5),
                Text(data['pharmacyName'] ?? "Shop", style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                Text(outOfStock ? "OUT OF STOCK" : "IN STOCK: $stock", 
                  style: TextStyle(color: outOfStock ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), minimumSize: const Size(double.infinity, 40)),
              onPressed: () => _handleOrder(data, outOfStock),
              child: Text(outOfStock ? "PRE-ORDER / NOTIFY ME" : "ORDER NOW", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _handleOrder(Map<String, dynamic> data, bool isPreBook) {
    if (userAddress.isEmpty || userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please update profile address & phone!")));
      _showProfileManager();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPreBook ? "Pre-order Notification" : "Confirm Order"),
        content: Text(isPreBook 
          ? "Notify back in stock at ${data['pharmacyName']}?"
          : "Order ${data['name']}?\nDelivery to: $userAddress"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('orders').add({
              'patientId': FirebaseAuth.instance.currentUser?.uid,
              'patientName': userName,
              'patientPhone': userPhone,
              'patientAddress': userAddress,
              'medicineName': data['name'],
              'pharmacyName': data['pharmacyName'],
              'pharmacyId': data['ownerId'], 
              'pharmacyPhone': data['phone'] ?? "",
              'price': data['price'],
              'status': isPreBook ? "Pre-Ordered" : "Pending",
              'timestamp': FieldValue.serverTimestamp(),
            });
            if (mounted) {
              Navigator.pop(context);
              _tabController.animateTo(2);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPreBook ? "Pre-order saved!" : "Order placed!")));
            }
          }, child: const Text("CONFIRM"))
        ],
      ),
    );
  }

  Widget _buildCitySelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    color: const Color(0xFF0D47A1),
    child: DropdownButton<String>(
      isExpanded: true, value: userCity, dropdownColor: const Color(0xFF0D47A1), iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      items: bangladeshDistricts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => userCity = v!),
    ),
  );

  Widget _buildSearchBar() => Padding(padding: const EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: InputDecoration(hintText: "Search medicine...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))));

  Widget _buildSpecificPharmacyProfile() => _buildPharmacyStockList();

  Widget _buildPharmacyStockList() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('medicines').where('ownerId', isEqualTo: selectedPharmacyId).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      var meds = snapshot.data!.docs;
      return ListView.builder(itemCount: meds.length, itemBuilder: (context, i) => _buildMedicineCard(meds[i].data() as Map<String, dynamic>));
    },
  );

  void _showProfileManager() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Delivery Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Full Name")), TextField(controller: editPhoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone), TextField(controller: editAddressController, decoration: const InputDecoration(labelText: "Address")), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800), onPressed: () { FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'name': editNameController.text, 'phone': editPhoneController.text, 'address': editAddressController.text}); Navigator.pop(context); }, child: const Text("Save Profile", style: TextStyle(color: Colors.white))), const SizedBox(height: 20)])));
  }

  Color _getStatusColor(String s) => s == "Accepted" ? Colors.blue : s == "On the Way" ? Colors.purple : s == "Delivered" ? Colors.green : Colors.orange;
  IconData _getStatusIcon(String s) => s == "Accepted" ? Icons.check_circle : s == "On the Way" ? Icons.delivery_dining : s == "Delivered" ? Icons.verified : Icons.hourglass_empty;
  
  Widget _orderStepIndicator(String status) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stepIcon(Icons.shopping_cart, "Ordered", true), _stepLine(status != "Pending"), _stepIcon(Icons.thumb_up, "Pharmacy", status != "Pending"), _stepLine(status == "On the Way" || status == "Delivered"), _stepIcon(Icons.delivery_dining, "Rider", status == "On the Way" || status == "Delivered"), _stepLine(status == "Delivered"), _stepIcon(Icons.done_all, "Received", status == "Delivered")]);
  Widget _stepIcon(IconData icon, String label, bool active) => Column(children: [Icon(icon, color: active ? Colors.green : Colors.grey, size: 20), Text(label, style: TextStyle(fontSize: 8, color: active ? Colors.black : Colors.grey))]);
  Widget _stepLine(bool active) => Container(width: 25, height: 2, color: active ? Colors.green : Colors.grey);

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    // FIX: Removed 'const' because LoginScreen is not a constant constructor
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
  }

  Future<void> _makeCall(String? n) async { if (n != null && n.isNotEmpty) { final Uri url = Uri.parse("tel:$n"); if (await canLaunchUrl(url)) await launchUrl(url); } }
}