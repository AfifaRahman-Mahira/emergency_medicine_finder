import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../data/dummy_data.dart';
import 'order_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
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
                labelText: 'Search Medicine',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => searchMedicine(searchController.text),
                ),
              ),
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
                            subtitle: Text(
                                '${med.pharmacy} - Stock: ${med.stock}'),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          OrderScreen(medicine: med)));
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
