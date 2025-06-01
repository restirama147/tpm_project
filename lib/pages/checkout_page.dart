import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/model/notification_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutPage extends StatefulWidget {
  final String selectedCurrency;
  final List<CartItem> selectedItems;

  const CheckoutPage({
    super.key,
    required this.selectedCurrency,
    required this.selectedItems,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Box<CartItem> cartBox;
  String currentUser = '';
  String selectedPayment = 'Credit Card';

  final List<String> paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'E-Wallet',
    'Cash on Delivery',
  ];

  final Map<String, double> conversionRates = {
    'EUR': 1.0,
    'USD': 1.1,
    'IDR': 17000.0,
  };

  LatLng? deliveryLatLng;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<CartItem>('cart_box');
    _loadCurrentUser();
    _determinePosition();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString('username') ?? '';
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      deliveryLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  String getConvertedPrice(String priceStr) {
    double basePrice = double.tryParse(priceStr) ?? 0.0;
    double converted = basePrice * conversionRates[widget.selectedCurrency]!;
    String symbol = widget.selectedCurrency == 'IDR'
        ? 'Rp'
        : widget.selectedCurrency == 'USD'
        ? '\$'
        : '€';
    return '$symbol${converted.toStringAsFixed(widget.selectedCurrency == 'IDR' ? 0 : 2)}';
  }

  double calculateTotal(List<CartItem> items) {
    double total = 0.0;
    for (var item in items) {
      double price = double.tryParse(item.price) ?? 0.0;
      total += price * item.quantity;
    }
    return total * conversionRates[widget.selectedCurrency]!;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser.isEmpty || deliveryLatLng == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cartItems = widget.selectedItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('No items selected.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return ListTile(
                          leading: Image.network(
                            item.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${getConvertedPrice(item.price)} x ${item.quantity}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${widget.selectedCurrency == 'IDR'
                        ? 'Rp'
                        : widget.selectedCurrency == 'USD'
                        ? '\$'
                        : '€'}${calculateTotal(cartItems).toStringAsFixed(widget.selectedCurrency == 'IDR' ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  DropdownButton<String>(
                    value: selectedPayment,
                    items: paymentMethods
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPayment = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Delivery Location:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        center: deliveryLatLng,
                        zoom: 13.0,
                        onTap: (tapPos, point) {
                          setState(() {
                            deliveryLatLng = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: deliveryLatLng!,
                              width: 60,
                              height: 60,
                              builder: (_) => const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${deliveryLatLng!.latitude.toStringAsFixed(4)}, ${deliveryLatLng!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Ganti bagian `onPressed` di tombol Checkout Now seperti ini:
                      onPressed: () async {
                        final total = calculateTotal(cartItems);
                        final location =
                            '${deliveryLatLng!.latitude.toStringAsFixed(4)}, ${deliveryLatLng!.longitude.toStringAsFixed(4)}';

                        final message =
                            'Checkout berhasil senilai ${widget.selectedCurrency == 'IDR'
                                ? 'Rp${total.toStringAsFixed(0)}'
                                : widget.selectedCurrency == 'USD'
                                ? '\$${total.toStringAsFixed(2)}'
                                : '€${total.toStringAsFixed(2)}'}';

                        // Simpan notifikasi ke Hive
                        final box = Hive.box<NotificationItem>('notification_box');
                        await box.add(
                          NotificationItem(
                            message: message,
                            timestamp: DateTime.now(),
                            paymentMethod: selectedPayment,
                          ),
                        );

                        // Tampilkan dialog sukses, lalu kembali ke halaman sebelumnya dengan hasil true
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Order Successful"),
                            content: Text(
                              "Thank you for your purchase!\n"
                              "Delivery to: $location\n"
                              "Payment: $selectedPayment",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // tutup dialog
                                  Navigator.pop(
                                    context,
                                    true,
                                  ); // kembali ke CartPage dengan hasil `true`
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Checkout Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
