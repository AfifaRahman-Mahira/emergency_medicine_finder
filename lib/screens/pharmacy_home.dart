import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
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

  // Inventory & Profile Controllers
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();
  final barcodeController = TextEditingController();
  final searchController = TextEditingController();
  
  final shopNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();

  String searchQuery = "";
  String currentPharmacyName = "";
  String pCity = ""; 
  String pPhone = "";
  String pAddress = "";
  double averageRating = 4.7; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    currentPharmacyName = widget.pharmacyName;
    _fetchPharmacyDetails();
  }

  void _fetchPharmacyDetails() async {
    if (uid.isEmpty) return;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          currentPharmacyName = doc.data()?['name'] ?? widget.pharmacyName;
          pCity = doc.data()?['city'] ?? "Update City";
          pPhone = doc.data()?['phone'] ?? "Update Phone";
          pAddress = doc.data()?['address'] ?? "Update Address";
          
          shopNameController.text = currentPharmacyName;
          phoneController.text = pPhone;
          addressController.text = pAddress;
          cityController.text = pCity;
        });
      }
    });
  }

  // --- SCANNER SYSTEM ---
  void _openScanner({required bool isAddingNew}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Scan Medicine Barcode", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String code = barcodes.first.rawValue ?? "";
                    Navigator.pop(context);
                    setState(() {
                      if (isAddingNew) {
                        barcodeController.text = code;
                      } else {
                        searchController.text = code;
                        searchQuery = code;
                      }
                    });
                  }
                },
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 16))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentPharmacyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Rating: ⭐ $averageRating", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _showSettingsSheet),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [Tab(text: "INVENTORY"), Tab(text: "LIVE ORDERS"), Tab(text: "HISTORY")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(),
          _buildOrdersTab(isHistory: false),
          _buildOrdersTab(isHistory: true),
        ],
      ),
    );
  }

  // --- 1. INVENTORY TAB ---
  Widget _buildInventoryTab() {
    return Column(
      children: [
        _buildStatsBar(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').where('ownerId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs.where((d) {
                String name = d['name'].toString().toLowerCase();
                String barcode = d['barcode']?.toString() ?? "";
                return name.contains(searchQuery.toLowerCase()) || barcode.contains(searchQuery);
              }).toList();

              if (docs.isEmpty) return _emptyState("No medicines found in stock.");

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: docs.length,
                itemBuilder: (context, index) => _medicineTile(docs[index].id, docs[index].data() as Map<String, dynamic>),
              );
            },
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox(Icons.location_on, pCity, Colors.blue),
          _statBox(Icons.phone, pPhone, Colors.green),
          _statBox(Icons.star, "Top Rated", Colors.orange),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, Color color) {
    return Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 10),
      child: TextField(
        controller: searchController,
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search name or scan barcode...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
          suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.orange), onPressed: () => _openScanner(isAddingNew: false)),
          filled: true, 
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Widget _medicineTile(String id, Map<String, dynamic> data) {
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    return Card(
      elevation: 0.5, 
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
        subtitle: Text("${data['generic']}\nPrice: BDT ${data['price']}", style: const TextStyle(fontSize: 13)),
        trailing: SizedBox(
          width: 50, // Fixed width to prevent overflow
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: stock < 10 ? Colors.red.shade50 : Colors.green.shade50, 
              borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox( // Prevents text from overflowing vertically or horizontally
                  child: Text("$stock", style: TextStyle(fontWeight: FontWeight.bold, color: stock < 10 ? Colors.red : Colors.green.shade700)),
                ),
                const Text("Qty", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        onLongPress: () => _deleteMedicine(id),
      ),
    );
  }

  // --- 2. ORDER TABS ---
  Widget _buildOrdersTab({required bool isHistory}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('pharmacyId', isEqualTo: uid)
          .where('status', isEqualTo: isHistory ? "Delivered" : "Pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return _emptyState(isHistory ? "No order history found." : "No pending orders today.");

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _orderCard(doc.id, data, isHistory);
          },
        );
      },
    );
  }

  Widget _orderCard(String id, Map<String, dynamic> data, bool isHistory) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        iconColor: const Color(0xFF1A237E),
        title: Text(data['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        subtitle: Text("Patient: ${data['patientName']}", style: const TextStyle(fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _orderInfoRow(Icons.phone_in_talk_rounded, "Call: ${data['patientPhone']}", isLink: true, phone: data['patientPhone']),
                _orderInfoRow(Icons.location_on_rounded, "Address: ${data['patientAddress']}"),
                _orderInfoRow(Icons.receipt_long_rounded, "Total Bill: BDT ${data['price']} (Qty: ${data['quantity']})"),
                const Divider(),
                if (!isHistory)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700, 
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => _deliverAndSyncStock(id, data),
                    icon: const Icon(Icons.verified_rounded, color: Colors.white),
                    label: const Text("MARK AS DELIVERED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _orderInfoRow(IconData icon, String text, {bool isLink = false, String? phone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isLink ? () => _makePhoneCall(phone!) : null,
        child: Row(children: [Icon(icon, size: 16, color: Colors.blueGrey), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: isLink ? Colors.blue.shade800 : Colors.black87, fontWeight: isLink ? FontWeight.bold : FontWeight.normal, fontSize: 13)))]),
      ),
    );
  }

  // --- FIREBASE LOGIC ---
  void _deliverAndSyncStock(String orderId, Map<String, dynamic> data) async {
    String medId = data['medicineId'] ?? "";
    int qty = data['quantity'] ?? 1;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'Delivered'});
      if (medId.isNotEmpty) {
        DocumentReference medRef = FirebaseFirestore.instance.collection('medicines').doc(medId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snap = await transaction.get(medRef);
          if (snap.exists) {
            int current = int.tryParse(snap['stock'].toString()) ?? 0;
            transaction.update(medRef, {'stock': (current - qty).clamp(0, 999999)});
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Delivered & Stock Updated!"), backgroundColor: Colors.green));
    } catch (e) { print(e); }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Update Pharmacy Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            _inputField(shopNameController, "Pharmacy Name", Icons.store),
            _inputField(phoneController, "Official Number", Icons.phone),
            _inputField(addressController, "Full Address", Icons.map),
            _inputField(cityController, "City", Icons.location_city),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () {
                FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': shopNameController.text, 'phone': phoneController.text,
                  'address': addressController.text, 'city': cityController.text,
                });
                Navigator.pop(context);
              },
              child: const Text("SAVE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showAddMedicineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Inventory Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              _inputField(nameController, "Medicine Name", Icons.medication_rounded),
              _inputField(genericController, "Generic Name", Icons.science_rounded),
              Row(children: [
                Expanded(child: _inputField(priceController, "Price (BDT)", Icons.payments_rounded, isNum: true)),
                const SizedBox(width: 15),
                Expanded(child: _inputField(stockController, "Stock Qty", Icons.inventory_2_rounded, isNum: true)),
              ]),
              const SizedBox(height: 15),
              TextField(
                controller: barcodeController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code_rounded), hintText: "Barcode (Scan or Type)",
                  suffixIcon: IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.blue), onPressed: () => _openScanner(isAddingNew: true)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E), 
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () {
                  if(nameController.text.isEmpty || priceController.text.isEmpty) return;
                  FirebaseFirestore.instance.collection('medicines').add({
                    'name': nameController.text, 'generic': genericController.text,
                    'price': priceController.text, 'stock': int.parse(stockController.text),
                    'barcode': barcodeController.text, 'ownerId': uid, 'pharmacyName': currentPharmacyName,
                    'city': pCity, 'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _clearControllers();
                },
                child: const Text("ADD TO STOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return Padding(padding: const EdgeInsets.only(top: 15), child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(prefixIcon: Icon(icon, size: 20), hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
  }

  void _deleteMedicine(String id) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("Delete Medicine?"), content: const Text("This item will be removed from your public stock."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), TextButton(onPressed: () { FirebaseFirestore.instance.collection('medicines').doc(id).delete(); Navigator.pop(context); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))]));
  }

  Widget _emptyState(String msg) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade300), const SizedBox(height: 15), Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14))])));

  void _clearControllers() { nameController.clear(); genericController.clear(); priceController.clear(); stockController.clear(); barcodeController.clear(); }
  void _makePhoneCall(String p) async { final Uri url = Uri(scheme: 'tel', path: p); if (await canLaunchUrl(url)) await launchUrl(url); }
  
  void _handleLogout() async { 
    await FirebaseAuth.instance.signOut(); 
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => LoginScreen()), 
        (route) => false,
      ); 
    }
  }

  Widget _buildAddButton() => Padding(padding: const EdgeInsets.all(15), child: ElevatedButton(onPressed: _showAddMedicineSheet, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), minimumSize: const Size(double.infinity, 55), elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("ADD NEW MEDICINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}