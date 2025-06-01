import 'package:flutter/material.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/model/data_model.dart';
import 'package:project_tpm/pages/cart_page.dart';
import 'package:project_tpm/pages/detail_page.dart';
import 'package:project_tpm/pages/login_page.dart';
import 'package:project_tpm/pages/profile_page.dart';
import 'package:project_tpm/service/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

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

  late Box<CartItem> cartBox;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _productList = AppService.getData();
    cartBox = Hive.box<CartItem>('cart_box');
    _loadCartItemsFromHive();
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
    setState(() {
      _selectedIndex = index;
    });

    // // Aksi berdasarkan item
    // if (index == 2) {
    //   _showInfoDialog("Profile", "Fitur Profile belum tersedia.");
    // } else if (index == 1) {
    //   _showInfoDialog("Notification", "Belum ada notifikasi.");
    // }
  }

  // void _showInfoDialog(String title, String message) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(title),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Tutup"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove("username");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hello, ${widget.username}"),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _selectedIndex == 0
            ? FutureBuilder<List<ModelApp>>(
                future: _productList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Gagal memuat produk."));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Tidak ada produk."));
                  } else {
                    return _buildProductList(snapshot.data!);
                  }
                },
              )
            : _selectedIndex == 1
            ? const Center(child: Text("Belum ada notifikasi."))
            : const ProfilePage(), // ← import dulu file-nya
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
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
    );
  }

  Widget _buildProductList(List<ModelApp> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        final isInCart = cartItems.contains(item.id);

        return Card(
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
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category: ${item.category ?? '-'}"),
                Text("Price: \$${item.price?.toStringAsFixed(2) ?? '-'}"),
                Text("Rating: ${item.rating?.rate ?? 0}"),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                color: isInCart ? Colors.pink : null,
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
