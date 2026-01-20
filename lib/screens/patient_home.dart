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
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          selectedPharmacyId == null ? "M-Pharma Patient" : selectedPharmacyName!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A237E), 
        elevation: 4,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: selectedPharmacyId != null
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => setState(() => selectedPharmacyId = null))
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.account_circle_outlined, size: 26), onPressed: _showProfileManager),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "STORES"),
            Tab(text: "BROWSE"),
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

  // --- 1. PHARMACY DIRECTORY ---
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
              if (pharmacies.isEmpty) return _emptyState("No registered pharmacies found in $userCity.");

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: pharmacies.length,
                itemBuilder: (context, i) {
                  var data = pharmacies[i].data() as Map<String, dynamic>;
                  String phId = pharmacies[i].id;
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF1A237E)),
                      ),
                      title: Text(data['name'] ?? "Unknown Shop", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(data['address'] ?? "Address not specified", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => setState(() {
                        selectedPharmacyId = phId;
                        selectedPharmacyName = data['name'];
                        selectedPharmacyData = data;
                        selectedPharmacyData!['id'] = phId;
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

  // --- 2. GLOBAL MEDICINE SEARCH ---
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
              
              final allMeds = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['city'] ?? "").toString().toLowerCase() == userCity.toLowerCase();
              }).toList();

              var filteredMeds = allMeds.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return query.isEmpty || data['name'].toString().toLowerCase().contains(query);
              }).toList();

              if (filteredMeds.isEmpty && query.isNotEmpty) {
                filteredMeds = allMeds.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['generic'].toString().toLowerCase().contains(query);
                }).toList();
              }

              if (filteredMeds.isEmpty) return _emptyState("No matching medicines found.");

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: filteredMeds.length,
                itemBuilder: (context, i) {
                  var data = filteredMeds[i].data() as Map<String, dynamic>;
                  data['docId'] = filteredMeds[i].id; 
                  return _buildMedicineCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. MY ORDERS ---
  Widget _buildOrdersTab() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _emptyState("You haven't placed any orders yet.");

        var orders = snapshot.data!.docs;
        orders.sort((a, b) {
          Timestamp? t1 = (a.data() as Map<String, dynamic>)['timestamp'];
          Timestamp? t2 = (b.data() as Map<String, dynamic>)['timestamp'];
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index].data() as Map<String, dynamic>;
            String status = order['status'] ?? "Pending";
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                iconColor: _getStatusColor(status),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
                ),
                title: Text("${order['medicineName']} (x${order['quantity']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text("Shop: ${order['pharmacyName']}\nTotal: BDT ${order['price']}", style: const TextStyle(fontSize: 12, height: 1.5)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 10),
                        _orderStepIndicator(status),
                        const SizedBox(height: 20),
                        _infoRow(Icons.payment_rounded, "Payment: ${order['paymentMethod']}"),
                        _infoRow(Icons.location_on_rounded, "Delivery: ${order['patientAddress']}"),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            onPressed: () => _makeCall(order['pharmacyPhone']),
                            icon: const Icon(Icons.phone_in_talk, size: 18),
                            label: const Text("CONTACT PHARMACY", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
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

  // --- ORDER DIALOG ---
  void _showOrderDialog(Map<String, dynamic> data) {
    int qty = 1;
    int maxStock = int.tryParse(data['stock'].toString()) ?? 0;
    String paymentMethod = "Cash on Delivery";
    double unitPrice = double.tryParse(data['price'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF1A237E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Pharmacy: ${data['pharmacyName']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _qtyBtn(Icons.remove, () => setDialogState(() { if(qty > 1) qty--; })),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text("$qty", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                  _qtyBtn(Icons.add, () => setDialogState(() { if(qty < maxStock) qty++; })),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: "Payment Method", border: InputBorder.none),
                items: ["Cash on Delivery", "Online Payment"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setDialogState(() => paymentMethod = val!),
              ),
              const SizedBox(height: 10),
              Text("Grand Total: BDT ${(unitPrice * qty).toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('orders').add({
                  'patientId': FirebaseAuth.instance.currentUser?.uid,
                  'patientName': userName,
                  'patientPhone': userPhone,
                  'patientAddress': userAddress,
                  'city': userCity,
                  'medicineName': data['name'],
                  'medicineId': data['docId'], 
                  'quantity': qty,
                  'pharmacyName': data['pharmacyName'],
                  'pharmacyId': data['ownerId'], 
                  'pharmacyPhone': data['phone'] ?? "",
                  'price': (unitPrice * qty).toInt(),
                  'paymentMethod': paymentMethod,
                  'status': "Pending",
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _tabController.animateTo(2); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order successfully placed!"), backgroundColor: Colors.green));
              },
              child: const Text("CONFIRM ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---
  Widget _buildMedicineCard(Map<String, dynamic> data) {
    int stock = int.tryParse(data['stock'].toString()) ?? 0;
    bool outOfStock = stock <= 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A237E))),
                  const SizedBox(height: 4),
                  Text("${data['generic']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("BDT ${data['price']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: outOfStock ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          outOfStock ? "Out of Stock" : "$stock Units Left", 
                          style: TextStyle(fontSize: 11, color: outOfStock ? Colors.red : Colors.green.shade700, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  Text("from ${data['pharmacyName']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: outOfStock ? Colors.grey.shade300 : const Color(0xFF1A237E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: outOfStock ? null : () => _showOrderDialog(data),
              child: Text(outOfStock ? "SOLD OUT" : "ORDER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificPharmacyProfile() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.storefront_rounded, size: 35, color: Color(0xFF1A237E))),
              const SizedBox(height: 15),
              Text(selectedPharmacyName ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
              const SizedBox(height: 5),
              Text(selectedPharmacyData?['address'] ?? "", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 15),
              ActionChip(
                avatar: const Icon(Icons.call, size: 16, color: Colors.white),
                label: const Text("Call Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green.shade600,
                onPressed: () => _makeCall(selectedPharmacyData?['phone']),
              )
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(children: [Icon(Icons.inventory_2_outlined, size: 18), SizedBox(width: 8), Text("AVAILABLE STOCK", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))]),
        ),
        Expanded(child: _buildPharmacyStockList()),
      ],
    );
  }

  Widget _buildCitySelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), 
    color: const Color(0xFF1A237E), 
    child: DropdownButton<String>(
      isExpanded: true, 
      value: userCity, 
      dropdownColor: const Color(0xFF1A237E), 
      iconEnabledColor: Colors.amberAccent, 
      underline: Container(), 
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), 
      items: bangladeshDistricts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
      onChanged: (v) => setState(() => userCity = v!)
    )
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 15, 14, 10), 
    child: TextField(
      onChanged: (v) => setState(() => query = v.toLowerCase()), 
      decoration: InputDecoration(
        hintText: "Search medicine or generic...", 
        prefixIcon: const Icon(Icons.search_rounded), 
        filled: true, 
        fillColor: Colors.white, 
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200))
      )
    )
  );

  Widget _buildPharmacyStockList() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('medicines').where('ownerId', isEqualTo: selectedPharmacyId).snapshots(), 
    builder: (context, snapshot) { 
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); 
      var meds = snapshot.data!.docs; 
      if(meds.isEmpty) return _emptyState("This pharmacy has no medicine listed."); 
      return ListView.builder(itemCount: meds.length, itemBuilder: (context, i) { 
        var data = meds[i].data() as Map<String, dynamic>; 
        data['docId'] = meds[i].id; 
        return _buildMedicineCard(data); 
      }); 
    }
  );

  void _showProfileManager() { 
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20), TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))), TextField(controller: editPhoneController, decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone))), TextField(controller: editAddressController, decoration: const InputDecoration(labelText: "Delivery Address", prefixIcon: Icon(Icons.home))), const SizedBox(height: 30), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () { FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'name': editNameController.text, 'phone': editPhoneController.text, 'address': editAddressController.text}); Navigator.pop(context); }, child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(height: 30)]))); 
  }

  Widget _qtyBtn(IconData icon, VoidCallback press) => InkWell(onTap: press, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)));
  Color _getStatusColor(String s) => s == "Accepted" ? Colors.blue.shade700 : s == "Delivered" ? Colors.green.shade700 : Colors.orange.shade800;
  IconData _getStatusIcon(String s) => s == "Accepted" ? Icons.check_circle_rounded : s == "Delivered" ? Icons.verified_rounded : Icons.pending_actions_rounded;
  Widget _orderStepIndicator(String status) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stepIcon(Icons.shopping_bag_outlined, "Placed", true), _stepLine(status != "Pending"), _stepIcon(Icons.thumb_up_outlined, "Accepted", status != "Pending"), _stepLine(status == "Delivered"), _stepIcon(Icons.local_shipping_outlined, "Delivered", status == "Delivered")]);
  Widget _stepIcon(IconData icon, String label, bool active) => Column(children: [Icon(icon, color: active ? Colors.green : Colors.grey.shade400, size: 22), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black87 : Colors.grey))]);
  Widget _stepLine(bool active) => Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 4), color: active ? Colors.green : Colors.grey.shade300));
  Widget _infoRow(IconData icon, String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(icon, size: 16, color: Colors.blueGrey), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)))]));
  Widget _emptyState(String msg) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade300), const SizedBox(height: 15), Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 15))])));
  void _handleLogout() async { await FirebaseAuth.instance.signOut(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false); }
  Future<void> _makeCall(String? n) async { if (n != null) { final Uri url = Uri.parse("tel:$n"); if (await canLaunchUrl(url)) await launchUrl(url); } }
}