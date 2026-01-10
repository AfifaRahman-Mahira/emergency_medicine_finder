import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../widgets/medicine_card.dart'; 
import 'login_screen.dart';

class PatientHome extends StatefulWidget {
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  late List displayList;

  @override
  void initState() {
    super.initState();
    displayList = List.from(allMedicines); // শুরুতে সব ডাটা লোড করা
  }

  void updateSearch(String query) {
    setState(() {
      displayList = allMedicines.where((med) =>
          med.name.toLowerCase().contains(query.toLowerCase()) ||
          med.genericName.toLowerCase().contains(query.toLowerCase())
      ).toList();
      displayList.sort((a, b) => a.distance.compareTo(b.distance));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Medicine Finder", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await logoutUser();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (_) => false);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => updateSearch(value),
              decoration: InputDecoration(
                hintText: "Search medicine or generic...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.blue.withValues(alpha: 0.05), // withValues fix
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text("No medicines found!"))
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) => MedicineCard(medicine: displayList[index]),
                  ),
          ),
        ],
      ),
    );
  }
}