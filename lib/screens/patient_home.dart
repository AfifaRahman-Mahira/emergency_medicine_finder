import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../widgets/custom_design.dart';
import 'login_screen.dart';

class PatientHome extends StatefulWidget {
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  String query = "";
  String userCity = "Dhaka"; 
  String userAddress = ""; 
  String userName = "User";
  
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
            
            editNameController.text = userName;
            editAddressController.text = userAddress;
            editPhoneController.text = doc.data()?['phone'] ?? "";
          });
        }
      });
    }
  }

  Future<void> _getCurrentLocation(StateSetter setModalState) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setModalState(() => editAddressController.text = "Fetching GPS...");
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        );
        setModalState(() {
          editAddressController.text = "Lat: ${position.latitude}, Lon: ${position.longitude}";
        });
      } catch (e) {
        setModalState(() => editAddressController.text = "GPS Error!");
      }
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number not available")));
      return;
    }
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch dialer")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text("Emergency Finder", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: _showProfileManager),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // City Selection Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: const Color(0xFF0D47A1),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text("City: ", style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: bangladeshDistricts.contains(userCity) ? userCity : "Dhaka",
                    dropdownColor: const Color(0xFF0D47A1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    underline: Container(),
                    items: bangladeshDistricts.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => userCity = val!);
                      String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
                      FirebaseFirestore.instance.collection('users').doc(uid).update({'city': val});
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search medicine or pharmacy...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                filled: true, 
                fillColor: Colors.white, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              
              stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                // --- ADVANCED MATCHING LOGIC ---
                final meds = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  

                  String pharmacyLoc = data['location'].toString().toLowerCase();
                  String medName = data['name'].toString().toLowerCase();
                  String pharmName = (data['pharmacyName'] ?? "").toString().toLowerCase();
                  String targetCity = userCity.toLowerCase();
                  String targetArea = userAddress.toLowerCase().trim();

                 
                  bool isSameCity = pharmacyLoc.contains(targetCity);
                  if (!isSameCity) return false;

                  if (query.isNotEmpty) {
                    return medName.contains(query) || pharmName.contains(query) || pharmacyLoc.contains(query);
                  }

                 
                  if (targetArea.isNotEmpty && !targetArea.startsWith("lat:")) {
                    return pharmacyLoc.contains(targetArea);
                  }

                  return true; 
                }).toList();

                if (meds.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  itemCount: meds.length,
                  itemBuilder: (context, i) {
                    final data = meds[i].data() as Map<String, dynamic>;
                    return _buildMedicineCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> data) {
    bool isOutOfStock = (data['stock'] ?? 0) <= 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("৳${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Text("Generic: ${data['generic']}", style: const TextStyle(color: Colors.black54)),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Expanded(child: Text("${data['pharmacyName']} (${data['location']})", 
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 8),
            Text("Stock: ${isOutOfStock ? 'Out of Stock' : data['stock']}", 
                style: TextStyle(color: isOutOfStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: isOutOfStock ? "PRE-BOOK" : "ORDER NOW",
                    onPressed: () => _handleOrder(data, isOutOfStock),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _makeCall(data['phone']), 
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleOrder(Map<String, dynamic> data, bool isPreBook) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'patientId': uid,
        'patientName': userName,
        'patientPhone': editPhoneController.text,
        'medicineName': data['name'],
        'pharmacyName': data['pharmacyName'],
        'price': data['price'],
        'type': isPreBook ? "Pre-Book" : "Order",
        'status': "Pending",
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Checkout your orders."), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order failed!"), backgroundColor: Colors.red));
    }
  }

  void _showProfileManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Manage Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              CustomTextField(controller: editNameController, label: "Your Name", icon: Icons.person),
              CustomTextField(controller: editPhoneController, label: "Phone", icon: Icons.phone),
              CustomTextField(controller: editAddressController, label: "Area (e.g. Uttara)", icon: Icons.home),
              TextButton.icon(
                onPressed: () => _getCurrentLocation(setModalState),
                icon: const Icon(Icons.my_location),
                label: const Text("Use GPS Location"),
              ),
              const SizedBox(height: 15),
              CustomButton(text: "SAVE UPDATES", onPressed: () async {
                String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
                String areaInput = editAddressController.text.trim();

                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'name': editNameController.text,
                  'phone': editPhoneController.text,
                  'address': areaInput,
                  'city': userCity,
                }, SetOptions(merge: true));

           
                setState(() {
                  userAddress = areaInput;
                });

                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
              }),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 70, color: Colors.grey),
          const SizedBox(height: 10),
          Text("No medicines in '$userAddress, $userCity'", style: const TextStyle(color: Colors.grey)),
          const Text("Try changing your Area or City", style: TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      ),
    );
  }
}