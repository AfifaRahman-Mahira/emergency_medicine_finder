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

  // Controllers for Adding Medicine
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();
  final barcodeController = TextEditingController();
  
  // Search & Profile Controllers
  final searchController = TextEditingController();
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

  // Real-time Profile Sync (Updates UI if shop name or city changes)
  void _listenToPharmacyProfile() {
    if (uid.isEmpty) return;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          currentPharmacyName = snapshot.data()?['pharmacyName'] ?? widget.pharmacyName;
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
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showEditProfileSheet),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "STOCK MANAGER"), Tab(text: "PATIENT ORDERS")],
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
    return Column(
      children: [
        _buildStatsBar(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search medicine or generic name...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines')
                .where('ownerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No medicines added yet."));
              
              var meds = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['name'].toString().toLowerCase().contains(searchQuery) ||
                       (data['generic'] ?? "").toString().toLowerCase().contains(searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: meds.length,
                itemBuilder: (context, index) {
                  var doc = meds[index];
                  var data = doc.data() as Map<String, dynamic>;
                  int stock = int.tryParse(data['stock'].toString()) ?? 0;
                  bool isLow = stock < 10;

                  return Card(
                    elevation: 1, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      onTap: () => _showQuickEdit(doc.id, data),
                      title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['generic']} • ৳${data['price']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("$stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLow ? Colors.red : Colors.blue)),
                          Text(isLow ? "LOW STOCK" : "IN STOCK", style: TextStyle(fontSize: 9, color: isLow ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  // --- 2. ORDER TAB ---
  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('pharmacyId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No patient requests found."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? "pending";
            bool isPending = status.toLowerCase() == "pending";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Icon(Icons.person_pin, color: isPending ? Colors.orange : Colors.green),
                title: Text(data['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Patient: ${data['patientName']} • ${status.toUpperCase()}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text("📍 Address: ${data['patientAddress']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 5),
                        Text("📞 Contact: ${data['patientPhone']}"),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _makeCall(data['patientPhone']),
                                icon: const Icon(Icons.call, size: 18),
                                label: const Text("CALL"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (isPending)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': 'Accepted'}),
                                  child: const Text("ACCEPT", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            if (!isPending)
                              const Expanded(child: Center(child: Text("✅ Accepted", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))),
                          ],
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

  // --- 3. DATABASE & STOCK LOGIC ---
  void _addMedicine() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;
    
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
    genericController.clear(); barcodeController.clear();
  }

  void _showQuickEdit(String docId, Map<String, dynamic> data) {
    final sEdit = TextEditingController(text: data['stock'].toString());
    final pEdit = TextEditingController(text: data['price'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${data['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sEdit, decoration: const InputDecoration(labelText: "Update Stock"), keyboardType: TextInputType.number),
            TextField(controller: pEdit, decoration: const InputDecoration(labelText: "Update Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => FirebaseFirestore.instance.collection('medicines').doc(docId).delete().then((_)=>Navigator.pop(context)), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () {
            FirebaseFirestore.instance.collection('medicines').doc(docId).update({
              'stock': int.tryParse(sEdit.text) ?? 0,
              'price': pEdit.text,
            });
            Navigator.pop(context);
          }, child: const Text("SAVE")),
        ],
      ),
    );
  }

  // --- 4. UI COMPONENTS & LOGOUT ---
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFF0D47A1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile(Icons.location_on, pCity),
          _statTile(Icons.verified, "Active Shop"),
          _statTile(Icons.timer, "24/7 Service"),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String text) => Column(children: [Icon(icon, color: Colors.white, size: 20), Text(text, style: const TextStyle(color: Colors.white, fontSize: 11))]);

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: CustomButton(text: "ADD NEW MEDICINE", onPressed: _showAddSheet)),
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

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Pharmacy Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          CustomTextField(controller: editNameController, label: "Pharmacy Name", icon: Icons.store),
          CustomTextField(controller: editPhoneController, label: "Contact Phone", icon: Icons.phone),
          CustomTextField(controller: editAddressController, label: "Full Address", icon: Icons.location_on),
          const SizedBox(height: 20),
          CustomButton(text: "UPDATE PROFILE", onPressed: () {
            FirebaseFirestore.instance.collection('users').doc(uid).update({
              'pharmacyName': editNameController.text,
              'phone': editPhoneController.text,
              'address': editAddressController.text,
            });
            Navigator.pop(context);
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Add Stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            CustomTextField(controller: nameController, label: "Medicine Name", icon: Icons.medication),
            CustomTextField(controller: genericController, label: "Generic Group", icon: Icons.science),
            CustomTextField(controller: priceController, label: "Price (৳)", icon: Icons.payments),
            CustomTextField(controller: stockController, label: "Quantity", icon: Icons.inventory),
            CustomTextField(controller: barcodeController, label: "Barcode (Optional)", icon: Icons.qr_code),
            const SizedBox(height: 20),
            CustomButton(text: "SAVE TO SYSTEM", onPressed: _addMedicine),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _openScanner({bool isAddingNew = false}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MobileScanner(onDetect: (capture) {
        final code = capture.barcodes.first.rawValue ?? "";
        Navigator.pop(context);
        if (isAddingNew) {
          barcodeController.text = code;
          _showAddSheet();
        } else {
          setState(() {
            searchController.text = code;
            searchQuery = code.toLowerCase();
          });
        }
      }),
    );
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    // THE FIX: Removed 'const' to prevent compiler crash
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => LoginScreen()), 
        (r) => false
      );
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}