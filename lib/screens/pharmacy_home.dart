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

  // Controllers
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

  // --- INVENTORY TAB ---
  Widget _buildInventoryTab() {
    return Column(
      children: [
        _buildStatsBar(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').where('ownerId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _emptyState("No medicines found in stock.");
              
              var docs = snapshot.data!.docs.where((d) {
                String name = d['name'].toString().toLowerCase();
                String barcode = d['barcode']?.toString() ?? "";
                return name.contains(searchQuery.toLowerCase()) || barcode.contains(searchQuery);
              }).toList();
              
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

  // --- ORDERS TAB (FIXED LOADING & FILTERING) ---
  Widget _buildOrdersTab({required bool isHistory}) {
    return StreamBuilder<QuerySnapshot>(
      // Simple query to avoid indexing errors, we filter status locally for reliability
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: uid) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(isHistory ? "No order history found." : "No active orders.");
        }

        // Local Filter
        var filteredDocs = snapshot.data!.docs.where((doc) {
          String status = (doc['status'] ?? 'pending').toString().toLowerCase();
          return isHistory ? status == 'delivered' : status != 'delivered';
        }).toList();

        if (filteredDocs.isEmpty) {
          return _emptyState(isHistory ? "No history yet." : "No active orders.");
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];
            return _orderCard(doc.id, doc.data() as Map<String, dynamic>, isHistory);
          },
        );
      },
    );
  }

  Widget _orderCard(String id, Map<String, dynamic> data, bool isHistory) {
    String status = (data['status'] ?? 'pending').toString().toLowerCase();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        initiallyExpanded: !isHistory,
        iconColor: const Color(0xFF1A237E),
        title: Text(data['medicineName'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        subtitle: Text("Status: ${status.toUpperCase()}", style: TextStyle(fontSize: 12, color: _getStatusColor(status), fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _orderInfoRow(Icons.person, "Patient: ${data['patientName']}"),
                _orderInfoRow(Icons.phone_in_talk_rounded, "Call: ${data['patientPhone']}", isLink: true, phone: data['patientPhone']),
                _orderInfoRow(Icons.location_on_rounded, "Address: ${data['patientAddress']}"),
                _orderInfoRow(Icons.receipt_long_rounded, "Total Bill: BDT ${data['price']} (Qty: ${data['quantity']})"),
                const Divider(),
                if (!isHistory) _buildActionButton(id, status, data),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(String orderId, String status, Map<String, dynamic> data) {
    if (status == 'pending') {
      return _actionBtn("ACCEPT ORDER", Colors.blue, Icons.check_circle, () {
        FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'accepted'});
      });
    } else if (status == 'accepted') {
      return _actionBtn("READY FOR PICKUP", Colors.orange, Icons.inventory, () {
        FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'ready_for_pickup'});
      });
    } else if (status == 'ready_for_pickup') {
       return _statusText("Waiting for Rider...", Colors.orange);
    } else if (status == 'shipped') {
      return _actionBtn("MARK AS DELIVERED", Colors.green, Icons.verified, () {
        _deliverAndSyncStock(orderId, data);
      });
    }
    return const SizedBox();
  }

  // --- LOGIC FUNCTIONS ---

  void _deliverAndSyncStock(String orderId, Map<String, dynamic> data) async {
    String medId = data['medicineId'] ?? "";
    int qty = int.tryParse(data['quantity'].toString()) ?? 1;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'delivered'});
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
    } catch (e) { debugPrint("Sync Error: $e"); }
  }

  // --- REUSABLE UI ---

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.red;
    if (status == 'accepted') return Colors.blue;
    if (status == 'ready_for_pickup') return Colors.orange;
    if (status == 'shipped') return Colors.purple;
    if (status == 'delivered') return Colors.green;
    return Colors.black;
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback tap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: tap, icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusText(String txt, Color col) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(txt, textAlign: TextAlign.center, style: TextStyle(color: col, fontWeight: FontWeight.bold)));

  Widget _orderInfoRow(IconData icon, String text, {bool isLink = false, String? phone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isLink ? () => _makePhoneCall(phone!) : null,
        child: Row(children: [Icon(icon, size: 16, color: Colors.blueGrey), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: isLink ? Colors.blue.shade800 : Colors.black87, fontWeight: isLink ? FontWeight.bold : FontWeight.normal, fontSize: 13)))]),
      ),
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
          filled: true, fillColor: Colors.white,
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
      elevation: 0.5, margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
        subtitle: Text("${data['generic']}\nPrice: BDT ${data['price']}", style: const TextStyle(fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: stock < 10 ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text("$stock Qty", style: TextStyle(fontWeight: FontWeight.bold, color: stock < 10 ? Colors.red : Colors.green)),
        ),
        onLongPress: () => _deleteMedicine(id),
      ),
    );
  }

  // --- BOTTOM SHEETS ---

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Profile Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          _inputField(shopNameController, "Pharmacy Name", Icons.store),
          _inputField(phoneController, "Official Number", Icons.phone),
          _inputField(addressController, "Full Address", Icons.map),
          _inputField(cityController, "City", Icons.location_city),
          const SizedBox(height: 30),
          _actionBtn("SAVE PROFILE", const Color(0xFF1A237E), Icons.save, () {
            FirebaseFirestore.instance.collection('users').doc(uid).update({'name': shopNameController.text, 'phone': phoneController.text, 'address': addressController.text, 'city': cityController.text});
            Navigator.pop(context);
          }),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  void _showAddMedicineSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            _actionBtn("ADD TO STOCK", const Color(0xFF1A237E), Icons.add, () {
              if(nameController.text.isEmpty || priceController.text.isEmpty) return;
              FirebaseFirestore.instance.collection('medicines').add({
                'name': nameController.text, 'generic': genericController.text,
                'price': priceController.text, 'stock': int.tryParse(stockController.text) ?? 0,
                'barcode': barcodeController.text, 'ownerId': uid, 'pharmacyName': currentPharmacyName,
                'city': pCity, 'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              _clearControllers();
            }),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return Padding(padding: const EdgeInsets.only(top: 15), child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(prefixIcon: Icon(icon, size: 20), hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
  }

  void _openScanner({required bool isAddingNew}) {
    showModalBottomSheet(
      context: context, builder: (context) => MobileScanner(onDetect: (capture) {
        final code = capture.barcodes.first.rawValue ?? "";
        Navigator.pop(context);
        setState(() { if (isAddingNew) barcodeController.text = code; else { searchController.text = code; searchQuery = code; } });
      }),
    );
  }

  void _deleteMedicine(String id) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Delete?"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")), TextButton(onPressed: () { FirebaseFirestore.instance.collection('medicines').doc(id).delete(); Navigator.pop(context); }, child: const Text("Yes"))]));
  }

  Widget _emptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade300), const SizedBox(height: 15), Text(msg, style: TextStyle(color: Colors.grey.shade500))]));
  void _clearControllers() { nameController.clear(); genericController.clear(); priceController.clear(); stockController.clear(); barcodeController.clear(); }
  void _makePhoneCall(String p) async { final Uri url = Uri(scheme: 'tel', path: p); if (await canLaunchUrl(url)) await launchUrl(url); }
  void _handleLogout() async { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false); }
  Widget _buildAddButton() => Padding(padding: const EdgeInsets.all(15), child: _actionBtn("ADD NEW MEDICINE", const Color(0xFF1A237E), Icons.add, _showAddMedicineSheet));
}