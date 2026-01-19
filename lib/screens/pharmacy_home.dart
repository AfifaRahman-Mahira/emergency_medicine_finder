import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; 
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

  // Inventory Controllers
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();
  final barcodeController = TextEditingController();
  final searchController = TextEditingController();
  
  // Profile Controllers
  final editNameController = TextEditingController(); 
  final editPhoneController = TextEditingController();
  final editAddressController = TextEditingController(); 

  String searchQuery = "";
  String pCity = "Dhaka"; 
  String currentPharmacyName = "";
  String pharmacyPhone = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentPharmacyName = widget.pharmacyName;
    _listenToPharmacyProfile();
  }

  // Real-time listener for pharmacy profile changes
  void _listenToPharmacyProfile() {
    if (uid.isEmpty) return;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          currentPharmacyName = snapshot.data()?['name'] ?? snapshot.data()?['pharmacyName'] ?? widget.pharmacyName;
          pCity = snapshot.data()?['city'] ?? "Dhaka";
          pharmacyPhone = snapshot.data()?['phone'] ?? "";
          editNameController.text = currentPharmacyName;
          editPhoneController.text = pharmacyPhone;
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
          IconButton(icon: const Icon(Icons.settings), onPressed: _showEditProfileSheet),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
                style: const TextStyle(color: Colors.black),
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

                  if (meds.isEmpty) return const Center(child: Text("No items in stock", style: TextStyle(color: Colors.black54)));

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

  // --- 2. LIVE ORDERS TAB (FIXED QUERY) ---
  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('pharmacyId', isEqualTo: uid)
          .snapshots(), // Removed orderBy temporarily to fix "Order not showing" issue
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No incoming orders.", style: TextStyle(color: Colors.black54)));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? "Pending";
            
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                ),
                title: Text(data['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                subtitle: Text("Patient: ${data['patientName']}", style: const TextStyle(color: Colors.black54)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _orderDetailRow(Icons.location_on, "Address: ${data['patientAddress']}"),
                        _orderDetailRow(Icons.phone, "Phone: ${data['patientPhone']}"),
                        _orderDetailRow(Icons.payments, "Bill Amount: ৳${data['price']}"),
                        const Divider(),
                        const Text("Change Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 10),
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

  Widget _statusBtn(String docId, String status, Color color, Map<String, dynamic> orderData) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 8)),
      onPressed: () async {
        if (status == "Delivered") {
          _deductStock(orderData['medicineName']);
        }
        await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': status});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order marked as $status")));
      },
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _deductStock(String? medName) async {
    if (medName == null) return;
    var query = await FirebaseFirestore.instance.collection('medicines')
        .where('ownerId', isEqualTo: uid)
        .where('name', isEqualTo: medName)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      int currentStock = int.tryParse(query.docs.first['stock'].toString()) ?? 0;
      if (currentStock > 0) {
        query.docs.first.reference.update({'stock': currentStock - 1});
      }
    }
  }

  Widget _orderDetailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Icon(icon, size: 16, color: const Color(0xFF0D47A1)), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)))]),
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
    bool isLowStock = stock < 5;

    return Card(
      color: isLowStock ? Colors.red.shade50 : Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isLowStock ? BorderSide(color: Colors.red.shade200, width: 1) : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => _showQuickEdit(docId, data),
        leading: isLowStock 
          ? const Icon(Icons.warning_amber_rounded, color: Colors.red) 
          : const Icon(Icons.medication, color: Color(0xFF0D47A1)),
        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isLowStock 
          ? const Text("LOW STOCK ALERT!", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
          : Text("Generic: ${data['generic']}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("৳${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text("Stock: $stock", style: TextStyle(color: isLowStock ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)),
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
          _statItem(Icons.verified, "Verified"),
          _statItem(Icons.inventory_2, "Stock Active"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) => Column(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))]);

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Row(
        children: [
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _showAddSheet,
            child: const Text("ADD NEW MEDICINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
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

  void _addMedicine() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Price are required!")));
      return;
    }
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
      'phone': pharmacyPhone,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    nameController.clear(); priceController.clear(); stockController.clear(); genericController.clear(); barcodeController.clear();
  }

  void _showQuickEdit(String docId, Map<String, dynamic> data) {
    final sEdit = TextEditingController(text: data['stock'].toString());
    final pEdit = TextEditingController(text: data['price'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update ${data['name']}"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: sEdit, decoration: const InputDecoration(labelText: "Update Stock Quantity"), keyboardType: TextInputType.number),
          TextField(controller: pEdit, decoration: const InputDecoration(labelText: "Update Price (৳)"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('medicines').doc(docId).delete();
            Navigator.pop(context);
          }, child: const Text("DELETE ITEM", style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () {
            FirebaseFirestore.instance.collection('medicines').doc(docId).update({
              'stock': int.tryParse(sEdit.text) ?? 0, 
              'price': pEdit.text
            });
            Navigator.pop(context);
          }, child: const Text("SAVE CHANGES")),
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
        TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Pharmacy Name", prefixIcon: Icon(Icons.store))),
        TextField(controller: editPhoneController, decoration: const InputDecoration(labelText: "Public Contact Phone", prefixIcon: Icon(Icons.phone))),
        TextField(controller: editAddressController, decoration: const InputDecoration(labelText: "Full Shop Address", prefixIcon: Icon(Icons.map))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
          onPressed: () {
            FirebaseFirestore.instance.collection('users').doc(uid).update({
              'name': editNameController.text,
              'pharmacyName': editNameController.text,
              'phone': editPhoneController.text,
              'address': editAddressController.text
            });
            Navigator.pop(context);
          },
          child: const Text("UPDATE PROFILE", style: TextStyle(color: Colors.white)),
        )),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _showAddSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Inventory Entry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextField(controller: nameController, decoration: const InputDecoration(labelText: "Medicine Name", prefixIcon: Icon(Icons.medication))),
        TextField(controller: genericController, decoration: const InputDecoration(labelText: "Generic Group", prefixIcon: Icon(Icons.science))),
        TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price", prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number),
        TextField(controller: stockController, decoration: const InputDecoration(labelText: "Stock Quantity", prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number),
        TextField(controller: barcodeController, decoration: const InputDecoration(labelText: "Barcode (Optional)", prefixIcon: Icon(Icons.qr_code))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
          onPressed: _addMedicine,
          child: const Text("ADD TO STOCK", style: TextStyle(color: Colors.white)),
        )),
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