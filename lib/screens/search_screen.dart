import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../models/medicine.dart';
import '../data/dummy_data.dart';
import 'order_screen.dart';
=======
import '../data/dummy_data.dart';
import 'order_screen.dart';
import '../models/medicine.dart';
>>>>>>> 474f9bb (Initial commit: added login page)

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
<<<<<<< HEAD
  _SearchScreenState createState() => _SearchScreenState();
=======
  State<SearchScreen> createState() => _SearchScreenState();
>>>>>>> 474f9bb (Initial commit: added login page)
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<Medicine> displayedMedicines = [];

  @override
  void initState() {
    super.initState();
    displayedMedicines = List.from(medicines);
  }

  void searchMedicine(String query) {
    setState(() {
      displayedMedicines = medicines
          .where((med) =>
              med.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Medicine')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
<<<<<<< HEAD
                labelText: 'Search Medicine',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchMedicine(searchController.text),
                ),
              ),
=======
                  labelText: 'Search Medicine',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => searchMedicine(searchController.text),
                  )),
>>>>>>> 474f9bb (Initial commit: added login page)
              onChanged: (value) => searchMedicine(value),
            ),
            SizedBox(height: 20),
            Expanded(
              child: displayedMedicines.isEmpty
                  ? Center(child: Text('No medicines found'))
                  : ListView.builder(
                      itemCount: displayedMedicines.length,
                      itemBuilder: (context, index) {
                        final med = displayedMedicines[index];
                        return Card(
                          child: ListTile(
                            title: Text(med.name),
<<<<<<< HEAD
                            subtitle: Text(
                                '${med.pharmacy} - Stock: ${med.stock}'),
=======
                            subtitle: Text('${med.pharmacy} - Stock: ${med.stock}'),
>>>>>>> 474f9bb (Initial commit: added login page)
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
<<<<<<< HEAD
                                      builder: (_) =>
                                          OrderScreen(medicine: med)));
=======
                                      builder: (_) => OrderScreen(medicine: med)));
>>>>>>> 474f9bb (Initial commit: added login page)
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
