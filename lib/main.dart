import 'package:flutter/material.dart';

// -------------------- MODELS --------------------
enum UserType { patient, pharmacyOwner, deliveryMan }

class User {
  final String email;
  final String password;
  final UserType type;

  User({required this.email, required this.password, required this.type});
}

class Medicine {
  final String name;
  final String pharmacy;
  int stock;
  final String? alternative;

  Medicine({
    required this.name,
    required this.pharmacy,
    required this.stock,
    this.alternative,
  });
}

// -------------------- DUMMY DATA --------------------
final List<User> users = [
  User(email: 'patient@example.com', password: '1234', type: UserType.patient),
  User(email: 'pharmacy@example.com', password: '1234', type: UserType.pharmacyOwner),
  User(email: 'delivery@example.com', password: '1234', type: UserType.deliveryMan),
];

final List<Medicine> medicines = [
  Medicine(name: 'Paracetamol', pharmacy: 'City Pharmacy', stock: 10),
  Medicine(name: 'Napa', pharmacy: 'Care Pharmacy', stock: 0, alternative: 'Napa Extra'),
  Medicine(name: 'Ibuprofen', pharmacy: 'HealthPlus', stock: 5),
];

final List<Map<String, dynamic>> orders = [];

// -------------------- MAIN --------------------
void main() {
  runApp(EmergencyMedicineFinderApp());
}

class EmergencyMedicineFinderApp extends StatelessWidget {
  const EmergencyMedicineFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Medicine Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

// -------------------- LOGIN SCREEN --------------------
class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  void login(BuildContext context) {
    String email = emailController.text.trim();
    String pass = passwordController.text.trim();

    // Null-safe way
    User? foundUser;
    for (var u in users) {
      if (u.email == email && u.password == pass) {
        foundUser = u;
        break;
      }
    }

    if (foundUser != null) {
      if (foundUser.type == UserType.patient) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => SearchScreen()));
      } else if (foundUser.type == UserType.pharmacyOwner) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => PharmacyHomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DeliveryHomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Emergency Medicine Finder',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => login(context),
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- SEARCH SCREEN --------------------
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
                            subtitle:
                                Text('${med.pharmacy} - Stock: ${med.stock}'),
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

// -------------------- ORDER SCREEN --------------------
class OrderScreen extends StatelessWidget {
  final Medicine medicine;

  const OrderScreen({super.key, required this.medicine});

  void placeOrder(BuildContext context) {
    orders.add({'medicine': medicine, 'patient': 'Demo Patient'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Medicine')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medicine: ${medicine.name}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Pharmacy: ${medicine.pharmacy}'),
            SizedBox(height: 10),
            Text('Stock: ${medicine.stock}'),
            SizedBox(height: 10),
            if (medicine.stock == 0 && medicine.alternative != null)
              Text('Alternative: ${medicine.alternative}',
                  style: TextStyle(color: Colors.green)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => placeOrder(context),
              child: Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- PHARMACY HOME --------------------
class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pharmacy Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Medicine Stock', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final med = medicines[index];
                  return Card(
                    child: ListTile(
                      title: Text(med.name),
                      subtitle: Text('${med.pharmacy} - Stock: ${med.stock}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          med.stock += 5;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stock updated')));
                        },
                      ),
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

// -------------------- DELIVERY HOME --------------------
class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: orders.isEmpty
            ? Center(child: Text('No deliveries assigned'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    child: ListTile(
                      title: Text(order['medicine'].name),
                      subtitle: Text('Patient: ${order['patient']}'),
                      trailing: ElevatedButton(
                        child: Text('Delivered'),
                        onPressed: () {
                          orders.removeAt(index);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
