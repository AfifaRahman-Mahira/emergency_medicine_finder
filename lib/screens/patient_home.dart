import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../data/dummy_data.dart';
import '../widgets/custom_design.dart';
import 'login_screen.dart';

class PatientHome extends StatefulWidget {
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  String query = "";
  String userLocation = "Dhaka"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Finder"), 
        backgroundColor: const Color(0xFF0D47A1), 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              currentUser = null;
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // location selection part
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: const Color(0xFF0D47A1),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text("Finding in: ", style: TextStyle(color: Colors.white70)),
                DropdownButton<String>(
                  value: userLocation,
                  dropdownColor: const Color(0xFF0D47A1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  underline: Container(),
                  items: ["Dhaka", "Chittagong", "Sylhet", "Rajshahi"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      userLocation = val!;
                    });
                  },
                ),
              ],
            ),
          ),
          
      
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search medicine or pharmacy...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                filled: true,
                fillColor: Colors.blue.withOpacity(0.1), // এখানে ফিক্স করা হয়েছে
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

         
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? "").toString().toLowerCase();
                  final phName = (data['pharmacyName'] ?? "").toString().toLowerCase();
                  final loc = (data['location'] ?? "").toString().toLowerCase();

                  final matchesQuery = name.contains(query.toLowerCase()) || 
                                       phName.contains(query.toLowerCase());
                  final matchesLocation = loc == userLocation.toLowerCase();
                  
                  return matchesQuery && matchesLocation;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text("No medicines found in $userLocation!"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final medData = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(medData['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("৳${medData['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.store, size: 16, color: Colors.blueAccent),
                                const SizedBox(width: 5),
                                Text(medData['pharmacyName'] ?? '', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("Generic: ${medData['generic'] ?? 'N/A'} | Stock: ${medData['stock']}"),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: CustomButton(text: "PRE-BOOK", onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Booking ${medData['name']} at ${medData['pharmacyName']}"))
                                  );
                                })),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green), 
                                    onPressed: () {
                          
                                    }
                                  ),
                                ),
                              ],
                            )
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
}