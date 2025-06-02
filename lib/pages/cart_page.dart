import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/pages/checkout_page.dart';
import 'package:project_tpm/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Box<CartItem> cartBox;
  String currentUser = '';
  String selectedCurrency = 'EUR';
  Set<String> selectedKeys = {};

  final Map<String, double> conversionRates = {
    'EUR': 1.0,
    'USD': 1.1,
    'IDR': 17000.0,
  };

  @override
  void initState() {
    super.initState();
    _initializeBoxAndUser();
  }

  Future<void> _initializeBoxAndUser() async {
    cartBox = await Hive.openBox<CartItem>('cart_box');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString('username') ?? '';
    });
  }

  void _removeItem(String key) {
    cartBox.delete(key);
    selectedKeys.remove(key);
    setState(() {});
  }

  String getConvertedPrice(String priceStr) {
    double basePrice = double.tryParse(priceStr) ?? 0.0;
    double converted = basePrice * conversionRates[selectedCurrency]!;
    String symbol = selectedCurrency == 'IDR'
        ? 'Rp'
        : selectedCurrency == 'USD'
            ? '\$'
            : '€';
    return '$symbol${converted.toStringAsFixed(selectedCurrency == 'IDR' ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cartKeys = cartBox.keys
        .where((key) => key.toString().startsWith(currentUser))
        .toList();

    final userCartItems = cartKeys
        .map((key) => MapEntry(key.toString(), cartBox.get(key)!))
        .toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 166, 192, 235),
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 14, 61, 127),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userCartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                _buildCurrencyDropdown(),
                Expanded(
                  child: ListView.builder(
                    itemCount: userCartItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final key = userCartItems[index].key;
                      final item = userCartItems[index].value;
                      final isSelected = selectedKeys.contains(key);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shadowColor: Color.fromARGB(255, 14, 61, 127).withOpacity(0.3),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedKeys.add(key);
                                    } else {
                                      selectedKeys.remove(key);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.image,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '${getConvertedPrice(item.price)} x ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeItem(key),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedKeys.isEmpty
                          ? null
                          : () async {
                              final selectedItems = selectedKeys
                                  .map((key) => cartBox.get(key)!)
                                  .toList();

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    selectedCurrency: selectedCurrency,
                                    selectedItems: selectedItems,
                                  ),
                                ),
                              );

                              if (result == true) {
                                // Hapus item yang dicheckout dari Hive
                                for (var key in selectedKeys) {
                                  await cartBox.delete(key);
                                }

                                selectedKeys.clear();

                                // Navigasi ke HomePage dan pindah ke tab Notifikasi
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomePage(
                                      username: currentUser,
                                      selectedIndex: 1,
                                    ),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedKeys.isEmpty
                            ? Colors.grey
                            : Color.fromARGB(255, 14, 61, 127),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: Color.fromARGB(255, 14, 61, 127),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Choose Currency:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          DropdownButton<String>(
            value: selectedCurrency,
            items: const [
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'IDR', child: Text('IDR')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCurrency = value;
                });
              }
            },
            dropdownColor: Color.fromARGB(255, 216, 229, 247),
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 60,
            color: Color.fromARGB(255, 14, 61, 127).withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty!!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'add items to cart',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(username: ''),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 14, 61, 127),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.shopping_bag,
              color: Colors.white.withOpacity(0.7),
            ),
            label: const Text(
              'Start Shopping',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
