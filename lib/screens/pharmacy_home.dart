import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; 
import '../widgets/custom_design.dart';

class PharmacyHome extends StatefulWidget {
  final String pharmacyName;
  const PharmacyHome({super.key, required this.pharmacyName});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  // Controllers for adding medicine
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final genericController = TextEditingController();
  
  // Controllers for editing profile
  final editNameController = TextEditingController(); 
  final editPhoneController = TextEditingController();
  final editAddressController = TextEditingController(); 
  
  // Controller for Search Bar
  final searchController = TextEditingController();
  String searchQuery = "";

  String pPhone = "Loading...";
  String pAddress = "Loading...";
  double pRating = 0.0; // Default set to 0.0
  String currentPharmacyName = "";
  String? selectedCity; 
  final List<String> cities = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna', 'Barisal', 'Rangpur', 'Mymensingh'];

  @override
  void initState() {
    super.initState();
    currentPharmacyName = widget.pharmacyName;
    _fetchPharmacyProfile();
  }

  // Fetch pharmacy profile from 'users' collection
  void _fetchPharmacyProfile() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          currentPharmacyName = doc.data()?['pharmacyName'] ?? doc.data()?['name'] ?? widget.pharmacyName;
          pPhone = doc.data()?['phone'] ?? "No Phone Found";
          pAddress = doc.data()?['address'] ?? "No Address Found";
          // If no rating field exists, it will remain 0.0
          pRating = (doc.data()?['rating'] ?? 0.0).toDouble();
        });
      }
    }
  }

  // Delete medicine from Firestore
  void _deleteMedicine(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Medicine"),
        content: const Text("Are you sure you want to remove this item from inventory?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('medicines').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine removed")));
      }
    }
  }

  void _showEditProfileSheet() {
    editNameController.text = currentPharmacyName;
    editPhoneController.text = pPhone;
    
    if (pAddress.contains(',')) {
      var parts = pAddress.split(',');
      selectedCity = cities.contains(parts[0].trim()) ? parts[0].trim() : null;
      editAddressController.text = parts.length > 1 ? parts.sublist(1).join(',').trim() : "";
    } else {
      editAddressController.text = pAddress;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Update Pharmacy Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                CustomTextField(controller: editNameController, label: "Pharmacy Name", icon: Icons.store),
                CustomTextField(controller: editPhoneController, label: "Contact Number", icon: Icons.phone),
                const Divider(),
                const Text("Location Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: cities.contains(selectedCity) ? selectedCity : null,
                  hint: const Text("Select District"),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.map_outlined),
                    filled: true,
                    fillColor: Colors.blue.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                  onChanged: (val) {
                    setModalState(() => selectedCity = val);
                  },
                ),
                const SizedBox(height: 15),
                CustomTextField(controller: editAddressController, label: "Detailed Road/Area Name", icon: Icons.location_on),
                TextButton.icon(
                  onPressed: () async {
                    LocationPermission permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                      setModalState(() => editAddressController.text = "Fetching GPS...");
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      setModalState(() => editAddressController.text = "Lat: ${position.latitude}, Lon: ${position.longitude}");
                    }
                  },
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                  label: const Text("Set Current Location via GPS"),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "SAVE ALL CHANGES", 
                  onPressed: () async {
                    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
                    String cityPart = selectedCity ?? "Dhaka";
                    String detailPart = editAddressController.text.trim();
                    String finalAddress = "$cityPart, $detailPart";
                    
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'pharmacyName': editNameController.text.trim(),
                        'name': editNameController.text.trim(),
                        'phone': editPhoneController.text.trim(),
                        'address': finalAddress,
                      }, SetOptions(merge: true));

                      _fetchPharmacyProfile(); 
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green)
                        );
                      }
                    } catch (e) {
                      debugPrint("Error updating profile: $e");
                    }
                  }
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addMedicine() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('medicines').add({
        'name': nameController.text.trim(),
        'generic': genericController.text.isEmpty ? "General" : genericController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0.0,
        'stock': int.tryParse(stockController.text) ?? 0,
        'pharmacyName': currentPharmacyName,
        'location': pAddress, 
        'timestamp': FieldValue.serverTimestamp(),
      });
      nameController.clear(); priceController.clear(); stockController.clear(); genericController.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAlternatives(String genericName, String currentMedName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicines')
            .where('generic', isEqualTo: genericName)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final alts = snapshot.data!.docs.where((doc) => doc['name'] != currentMedName).toList();
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text("Alternatives for $genericName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: alts.isEmpty 
                    ? const Center(child: Text("No alternatives found!"))
                    : ListView.builder(
                        itemCount: alts.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(alts[i]['name']),
                          subtitle: Text("Price: ৳${alts[i]['price']}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(currentPharmacyName),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(icon: const Icon(Icons.account_circle), onPressed: () => _showPharmacyProfile()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          
          // Search Bar Implementation
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search in inventory...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddSheet(), 
                  icon: const Icon(Icons.add), 
                  label: const Text("Add New"),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .where('pharmacyName', isEqualTo: currentPharmacyName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No medicines added yet."));
                
                // Filter list based on search query
                final meds = snapshot.data!.docs.where((doc) {
                  return doc['name'].toString().toLowerCase().contains(searchQuery);
                }).toList();

                if (meds.isEmpty) return const Center(child: Text("No matching medicine found."));

                return ListView.builder(
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    var data = meds[index].data() as Map<String, dynamic>;
                    var docId = meds[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        onTap: () => _showAlternatives(data['generic'], data['name']),
                        onLongPress: () => _deleteMedicine(docId), // Long press to delete
                        title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['generic']} | ৳${data['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStockControls(docId, data['stock']),
                            const SizedBox(width: 5),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _deleteMedicine(docId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockControls(String docId, int currentStock) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
          onPressed: () { if (currentStock > 0) FirebaseFirestore.instance.collection('medicines').doc(docId).update({'stock': currentStock - 1}); },
        ),
        Text("$currentStock", style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
          onPressed: () { FirebaseFirestore.instance.collection('medicines').doc(docId).update({'stock': currentStock + 1}); },
        ),
      ],
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Quick Inventory Update", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scanner opening..."))); }, 
              icon: const Icon(Icons.camera_alt), 
              label: const Text("SCAN BARCODE"),
            ),
            const Divider(),
            CustomTextField(controller: nameController, label: "Medicine Name", icon: Icons.medication),
            CustomTextField(controller: genericController, label: "Generic Name", icon: Icons.science),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: priceController, label: "Price", icon: Icons.attach_money)),
                const SizedBox(width: 10),
                Expanded(child: CustomTextField(controller: stockController, label: "Initial Stock", icon: Icons.inventory)),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(text: "SAVE TO INVENTORY", onPressed: _addMedicine),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPharmacyProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("$currentPharmacyName Info", overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                Navigator.pop(context);
                _showEditProfileSheet(); 
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 Location: $pAddress", style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text("📞 Contact: $pPhone"),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                Text(pRating == 0.0 ? " No Rating yet" : " $pRating (Real User Rating)"),
              ],
            ),
            const Divider(),
            const Text("Tip:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text("Click the edit icon above to update your info."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String cityHead = pAddress.contains(',') ? pAddress.split(',')[0] : "Loading...";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Dynamic Rating Logic
          Column(children: [
            const Icon(Icons.star, color: Colors.white), 
            Text(pRating == 0.0 ? "No Rating" : "Rating: $pRating", style: const TextStyle(color: Colors.white))
          ]),
          
          Column(children: [
            const Icon(Icons.location_on, color: Colors.white), 
            Text(cityHead, style: const TextStyle(color: Colors.white))
          ]),
          
          const Column(children: [
            Icon(Icons.access_time, color: Colors.white), 
            Text("24/7 Open", style: TextStyle(color: Colors.white)) // Swapped Verified with Shop Status
          ]),
        ],
      ),
    );
  } 
}