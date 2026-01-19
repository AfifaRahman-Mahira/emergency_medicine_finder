import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart'; 
import '../widgets/custom_design.dart';
import 'login_screen.dart';

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  const PharmacyHome({super.key, required this.pharmacyName});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Controllers for adding/editing medicines
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();
  final barcodeController = TextEditingController();
  final searchController = TextEditingController();
  
  // Controllers for pharmacy profile
  final editNameController = TextEditingController(); 
  final editPhoneController = TextEditingController();
  final editAddressController = TextEditingController(); 

  String searchQuery = "";
  String pCity = "Dhaka"; 
  String currentPharmacyName = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentPharmacyName = widget.pharmacyName;
    _listenToPharmacyProfile();
  }

  // Listen to profile changes to keep the pharmacy info updated for patients
  void _listenToPharmacyProfile() {
    if (uid.isEmpty) return;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          currentPharmacyName = snapshot.data()?['name'] ?? snapshot.data()?['pharmacyName'] ?? widget.pharmacyName;
          pCity = snapshot.data()?['city'] ?? "Dhaka";
          editNameController.text = currentPharmacyName;
          editPhoneController.text = snapshot.data()?['phone'] ?? "";
          editAddressController.text = snapshot.data()?['address'] ?? "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(currentPharmacyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showEditProfileSheet),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          tabs: const [Tab(text: "INVENTORY"), Tab(text: "LIVE ORDERS")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInventoryTab(), _buildOrdersTab()],
      ),
    );
  }

  // --- 1. INVENTORY TAB ---
  Widget _buildInventoryTab() {
    return Stack(
      children: [
        Column(
          children: [
            _buildStatsBar(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search stock...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('medicines')
                    .where('ownerId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  var meds = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['name'].toString().toLowerCase().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: meds.length,
                    itemBuilder: (context, index) {
                      var data = meds[index].data() as Map<String, dynamic>;
                      return _buildMedicineCard(meds[index].id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        _buildBottomActions(),
      ],
    );
  }

  // --- 2. LIVE ORDERS TAB (REAL-TIME UPDATES) ---
  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('pharmacyId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No incoming orders."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? "Pending";
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                ),
                title: Text(data['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("From: ${data['patientName']}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _orderDetailRow(Icons.location_on, "Address: ${data['patientAddress']}"),
                        _orderDetailRow(Icons.phone, "Phone: ${data['patientPhone']}"),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statusBtn(doc.id, "Accepted", Colors.blue, data),
                            _statusBtn(doc.id, "On the Way", Colors.orange, data),
                            _statusBtn(doc.id, "Delivered", Colors.green, data),
                          ],
                        ),
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

  // --- LOGIC: STATUS UPDATE & STOCK DEDUCTION ---
  Widget _statusBtn(String docId, String status, Color color, Map<String, dynamic> orderData) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () async {
        // Automatically deduct stock if the order is marked as delivered
        if (status == "Delivered") {
          _deductStock(orderData['medicineName']);
        }
        await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': status});
      },
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  // Function to search medicine and subtract 1 from stock
  void _deductStock(String? medName) async {
    if (medName == null) return;
    var query = await FirebaseFirestore.instance.collection('medicines')
        .where('ownerId', isEqualTo: uid)
        .where('name', isEqualTo: medName)
        .get();
    
    if (query.docs.isNotEmpty) {
      int currentStock = int.tryParse(query.docs.first['stock'].toString()) ?? 0;
      if (currentStock > 0) {
        query.docs.first.reference.update({'stock': currentStock - 1});
      }
    }
  }

  // --- UI COMPONENTS ---
  Widget _orderDetailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12)))]),
  );

  Color _getStatusColor(String status) {
    if (status == "Accepted") return Colors.blue;
    if (status == "On the Way") return Colors.orange;
    if (status == "Delivered") return Colors.green;
    return Colors.redAccent;
  }

  IconData _getStatusIcon(String status) {
    if (status == "Accepted") return Icons.check_circle;
    if (status == "On the Way") return Icons.local_shipping;
    if (status == "Delivered") return Icons.verified;
    return Icons.hourglass_top;
  }

  Widget _buildMedicineCard(String docId, Map<String, dynamic> data) {
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () => _showQuickEdit(docId, data),
        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Generic: ${data['generic']}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("৳${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text("Stock: $stock", style: TextStyle(color: stock < 5 ? Colors.red : Colors.blue, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFF0D47A1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.location_on, pCity),
          _statItem(Icons.verified_user, "Verified"),
          _statItem(Icons.inventory_2, "Live Stock"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) => Column(children: [Icon(icon, color: Colors.white, size: 18), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]);

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Row(
        children: [
          Expanded(child: CustomButton(text: "ADD MEDICINE", onPressed: _showAddSheet)),
          const SizedBox(width: 10),
          FloatingActionButton(
            backgroundColor: const Color(0xFF0D47A1),
            onPressed: () => _openScanner(isAddingNew: true),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          )
        ],
      ),
    );
  }

  // --- DATABASE OPERATIONS ---
  void _addMedicine() async {
    if (nameController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('medicines').add({
      'name': nameController.text.trim(),
      'generic': genericController.text.trim(),
      'price': priceController.text.trim(),
      'stock': int.tryParse(stockController.text) ?? 0,
      'barcode': barcodeController.text.trim(),
      'ownerId': uid,
      'pharmacyId': uid,
      'pharmacyName': currentPharmacyName,
      'city': pCity,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    nameController.clear(); priceController.clear(); stockController.clear();
  }

  void _showQuickEdit(String docId, Map<String, dynamic> data) {
    final sEdit = TextEditingController(text: data['stock'].toString());
    final pEdit = TextEditingController(text: data['price'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${data['name']}"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: sEdit, decoration: const InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
          TextField(controller: pEdit, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('medicines').doc(docId).delete();
            Navigator.pop(context);
          }, child: const Text("DELETE", style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () {
            FirebaseFirestore.instance.collection('medicines').doc(docId).update({
              'stock': int.tryParse(sEdit.text) ?? 0, 
              'price': pEdit.text
            });
            Navigator.pop(context);
          }, child: const Text("SAVE")),
        ],
      ),
    );
  }

  void _showEditProfileSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Pharmacy Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 15),
        CustomTextField(controller: editNameController, label: "Pharmacy Name", icon: Icons.store),
        CustomTextField(controller: editPhoneController, label: "Public Phone", icon: Icons.phone),
        CustomTextField(controller: editAddressController, label: "Full Shop Address", icon: Icons.map),
        const SizedBox(height: 20),
        CustomButton(text: "UPDATE PROFILE", onPressed: () {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'name': editNameController.text, // Updated 'name' field for consistency
            'pharmacyName': editNameController.text,
            'phone': editPhoneController.text,
            'address': editAddressController.text
          });
          Navigator.pop(context);
        }),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _showAddSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Inventory Entry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        CustomTextField(controller: nameController, label: "Medicine Name", icon: Icons.medication),
        CustomTextField(controller: genericController, label: "Generic Group", icon: Icons.science),
        CustomTextField(controller: priceController, label: "Price", icon: Icons.payments),
        CustomTextField(controller: stockController, label: "Stock Quantity", icon: Icons.inventory),
        CustomTextField(controller: barcodeController, label: "Barcode (Scan to fill)", icon: Icons.qr_code),
        const SizedBox(height: 20),
        CustomButton(text: "ADD TO STOCK", onPressed: _addMedicine),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _openScanner({bool isAddingNew = false}) {
    showModalBottomSheet(context: context, builder: (context) => MobileScanner(onDetect: (capture) {
      final code = capture.barcodes.first.rawValue ?? "";
      Navigator.pop(context);
      if (isAddingNew) { 
        barcodeController.text = code; 
        _showAddSheet(); 
      } else { 
        searchController.text = code; 
        setState(() => searchQuery = code.toLowerCase()); 
      }
    }));
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (r) => false);
  }
}