import 'package:flutter/material.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/model/data_model.dart';
import 'package:project_tpm/pages/cart_page.dart';
import 'package:project_tpm/pages/detail_page.dart';
import 'package:project_tpm/pages/notification_page.dart';
import 'package:project_tpm/pages/profile_page.dart';
import 'package:project_tpm/service/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  final String username;
  final int selectedIndex;

  const HomePage({super.key, required this.username, this.selectedIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<ModelApp>> _productList;
  Set<int> cartItems = {};
  int _selectedIndex = 0;

  bool isDarkMode = false;
  late final Stream<AccelerometerEvent> _accelerometerStream;
  double shakeThreshold = 15.0;

  late Box<CartItem> cartBox;

  String _searchQuery = '';
  String _sortBy = 'name'; // or 'rating'
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    "men's clothing",
    "women's clothing",
    'electronics',
    'jewelery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _productList = AppService.getData();
    cartBox = Hive.box<CartItem>('cart_box');
    _loadCartItemsFromHive();
    _accelerometerStream = SensorsPlatform.instance.accelerometerEvents;
    _accelerometerStream.listen((AccelerometerEvent event) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      double shake = (acceleration - 9.8).abs();

      if (shake > shakeThreshold) {
        setState(() {
          isDarkMode = !isDarkMode;
        });
      }
    });
  }

  void _loadCartItemsFromHive() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';

    final keys = cartBox.keys
        .where((key) => key.toString().startsWith(username))
        .toList();

    final items = keys
        .map((key) => cartBox.get(key))
        .where((item) => item != null)
        .map((item) => item!.id)
        .toSet();

    setState(() {
      cartItems = items;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex)
      return; // kalau sudah di halaman itu, tidak perlu apa-apa
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home tetap di halaman ini
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 166, 192, 235),
        appBar: AppBar(
          title: Text(
            "Hello, ${widget.username}",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 14, 61, 127),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                ),
                if (cartItems.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 8,
                      child: Text(
                        cartItems.length.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(25,25,25,0),
          child: _selectedIndex == 0
              ? Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          dropdownColor: Color.fromARGB(255, 216, 229, 247),
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Sort by Name A-Z'),
                            ),
                            DropdownMenuItem(
                              value: 'rating',
                              child: Text('Sort by Rating'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        DropdownButton<String>(
                          dropdownColor: Color.fromARGB(255, 216, 229, 247),
                          value: _selectedCategory,
                          items: _categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<ModelApp>>(
                        future: _productList,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text("Gagal memuat produk."),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("Tidak ada produk."),
                            );
                          } else {
                            List<ModelApp> filtered = snapshot.data!
                                .where(
                                  (item) =>
                                      (_selectedCategory == 'All' ||
                                          item.category == _selectedCategory) &&
                                      (item.title?.toLowerCase() ?? '')
                                          .contains(_searchQuery),
                                )
                                .toList();

                            if (_sortBy == 'name') {
                              filtered.sort(
                                (a, b) =>
                                    (a.title ?? '').compareTo(b.title ?? ''),
                              );
                            } else if (_sortBy == 'rating') {
                              filtered.sort(
                                (b, a) => (a.rating?.rate ?? 0).compareTo(
                                  b.rating?.rate ?? 0,
                                ),
                              );
                            }

                            return _buildProductList(filtered);
                          }
                        },
                      ),
                    ),
                  ],
                )
              : _selectedIndex == 1
              ? const NotificationPage()
              : const ProfilePage(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromARGB(255, 14, 61, 127),
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notification',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<ModelApp> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        final isInCart = cartItems.contains(item.id);

        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: Image.network(
              item.image ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            ),
            title: Text(
              item.title ?? 'No Title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${item.category}"),
                Text(
                  "${item.price?.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.green),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text("${item.rating?.rate}"),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                color: isInCart ? Color.fromARGB(255, 14, 61, 127) : null,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final username = prefs.getString('username') ?? '';
                final cartKey = '$username-${item.id}';

                setState(() {
                  if (isInCart) {
                    cartItems.remove(item.id);
                    cartBox.delete(cartKey);
                  } else {
                    cartItems.add(item.id!);
                    cartBox.put(
                      cartKey,
                      CartItem(
                        id: item.id!,
                        name: item.title ?? '',
                        price: item.price?.toString() ?? '0.0',
                        quantity: 1,
                        image: item.image ?? '',
                        userKey: username,
                      ),
                    );
                  }
                });
              },
            ),
            onTap: () {
              if (item.id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(id: item.id!)),
                );
              }
            },
          ),
        );
      },
    );
  }
}
