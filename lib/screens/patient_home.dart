import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../widgets/custom_design.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    _fetchPatientProfile(); 
  }

  // Real-time Profile Listener
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
        title: const Text("Emergency Finder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: "Find"),
            Tab(icon: Icon(Icons.shopping_bag), text: "My Orders"),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: _showProfileManager),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  // --- TAB 1: SEARCH MEDICINES ---
  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildCitySelector(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

              final meds = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String pharmacyCity = (data['city'] ?? "").toString().toLowerCase();
                String medName = (data['name'] ?? "").toString().toLowerCase();
                String generic = (data['generic'] ?? "").toString().toLowerCase();
                
                bool cityMatch = pharmacyCity.contains(userCity.toLowerCase());
                bool searchMatch = query.isEmpty || medName.contains(query) || generic.contains(query);
                
                return cityMatch && searchMatch;
              }).toList();

              if (meds.isEmpty) return _buildEmptyState();

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

  // --- TAB 2: ORDER STATUS TRACKING ---
  Widget _buildOrdersTab() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No orders found."));

        var docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var order = docs[index].data() as Map<String, dynamic>;
            String status = order['status'] ?? "pending";
            bool isAccepted = status.toLowerCase() == "accepted";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAccepted ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Icon(
                    isAccepted ? Icons.check : Icons.access_time,
                    color: isAccepted ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(order['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Pharmacy: ${order['pharmacyName']}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAccepted ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildCitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      color: const Color(0xFF0D47A1),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: bangladeshDistricts.contains(userCity) ? userCity : "Dhaka",
              dropdownColor: const Color(0xFF0D47A1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              items: bangladeshDistricts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() => userCity = val!);
                FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'city': val});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        onChanged: (v) => setState(() => query = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search medicine or generic...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> data) {
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    bool outOfStock = stock <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                Text("৳${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 5),
            Text("Generic: ${data['generic']}", style: const TextStyle(color: Colors.grey)),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(child: Text(data['pharmacyName'] ?? "Shop", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500))),
                Text("Stock: ${outOfStock ? 'None' : stock}", style: TextStyle(color: outOfStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleOrder(data, outOfStock),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                    child: Text(outOfStock ? "PRE-BOOK" : "ORDER NOW", style: const TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _makeCall(data['phone'] ?? data['pharmacyPhone']),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  void _handleOrder(Map<String, dynamic> data, bool isPreBook) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userAddress.isEmpty || userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please update your profile first!")));
      _showProfileManager();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPreBook ? "Pre-book Medicine?" : "Confirm Order?"),
        content: Text("Send request to ${data['pharmacyName']} for ${data['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('orders').add({
                'patientId': uid,
                'patientName': userName,
                'patientPhone': userPhone,
                'patientAddress': userAddress,
                'medicineName': data['name'],
                'pharmacyName': data['pharmacyName'],
                'pharmacyId': data['ownerId'] ?? data['pharmacyId'], 
                'price': data['price'],
                'status': "pending",
                'timestamp': FieldValue.serverTimestamp(),
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent! Check 'My Orders' tab."), backgroundColor: Colors.green));
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  void _showProfileManager() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Manage Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              CustomTextField(controller: editNameController, label: "Your Name", icon: Icons.person),
              CustomTextField(controller: editPhoneController, label: "Phone Number", icon: Icons.phone),
              CustomTextField(controller: editAddressController, label: "Delivery Address", icon: Icons.home),
              const SizedBox(height: 10),
              TextButton.icon(onPressed: () => _getCurrentLocation(setModalState), icon: const Icon(Icons.my_location), label: const Text("Get Current GPS")),
              const SizedBox(height: 15),
              CustomButton(text: "SAVE PROFILE", onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
                  'name': editNameController.text.trim(),
                  'phone': editPhoneController.text.trim(),
                  'address': editAddressController.text.trim(),
                });
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation(StateSetter setModalState) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position pos = await Geolocator.getCurrentPosition();
    setModalState(() => editAddressController.text = "${pos.latitude}, ${pos.longitude}");
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    // THE FIX: Removed 'const' keyword here
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => LoginScreen()), 
        (r) => false
      );
    }
  }

  Future<void> _makeCall(String? num) async {
    if (num == null || num.isEmpty) return;
    final Uri url = Uri.parse("tel:$num");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No medicine found in this city.", style: TextStyle(color: Colors.grey)));
  }
}