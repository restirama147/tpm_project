import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/model/notification_item.dart';
import 'package:project_tpm/pages/notification_page.dart';
import 'package:project_tpm/utils/notification_service.dart';
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
  LatLng? deliveryLatLng;

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

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<CartItem>('cart_box');
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString('username') ?? '';
    });
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      status = await Permission.location.request();
    }
    if (status.isGranted) {
      _determinePosition();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi dibutuhkan untuk checkout.')),
        );
      }
    }
  }

  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

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
    final basePrice = double.tryParse(priceStr) ?? 0.0;
    final converted = basePrice * (conversionRates[widget.selectedCurrency] ?? 1.0);
    final symbol = widget.selectedCurrency == 'IDR'
        ? 'Rp'
        : widget.selectedCurrency == 'USD'
            ? '\$'
            : '€';
    return '$symbol${converted.toStringAsFixed(widget.selectedCurrency == 'IDR' ? 0 : 2)}';
  }

  double calculateTotal(List<CartItem> items) {
    return items.fold(
      0.0,
      (sum, item) {
        final price = double.tryParse(item.price) ?? 0.0;
        return sum + (price * item.quantity);
      },
    ) * (conversionRates[widget.selectedCurrency] ?? 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser.isEmpty || deliveryLatLng == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cartItems = widget.selectedItems;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 166, 192, 235),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 14, 61, 127),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('No items selected.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 14, 61, 127))),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (_, index) {
                        final item = cartItems[index];
                        return ListTile(
                          leading: Image.network(item.image, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                          title: Text(item.name),
                          subtitle: Text('${getConvertedPrice(item.price)} x ${item.quantity}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${getConvertedPrice(calculateTotal(cartItems).toString())}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    dropdownColor: const Color.fromARGB(255, 216, 229, 247),
                    value: selectedPayment,
                    items: paymentMethods.map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                    onChanged: (value) => setState(() => selectedPayment = value ?? selectedPayment),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Delivery Location:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: FlutterMap(
                      options: MapOptions(
                        center: deliveryLatLng,
                        zoom: 13.0,
                        onTap: (_, point) => setState(() => deliveryLatLng = point),
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.app'),
                        MarkerLayer(markers: [
                          Marker(
                            point: deliveryLatLng!,
                            width: 60,
                            height: 60,
                            builder: (_) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ]),
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
                        backgroundColor: const Color.fromARGB(255, 14, 61, 127),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final total = calculateTotal(cartItems);
                        final symbol = widget.selectedCurrency == 'IDR'
                            ? 'Rp'
                            : widget.selectedCurrency == 'USD'
                                ? '\$'
                                : '€';
                        final message = 'Checkout berhasil senilai $symbol${total.toStringAsFixed(widget.selectedCurrency == 'IDR' ? 0 : 2)}';

                        final box = Hive.box<NotificationItem>('notification_box');
                        await box.add(NotificationItem(
                          message: message,
                          timestamp: DateTime.now(),
                          paymentMethod: selectedPayment,
                        ));

                        await NotificationService.show('Checkout Berhasil', message);

                        // Hapus item dari Hive cart
                        final keysToRemove = cartBox.keys.where((key) {
                          final item = cartBox.get(key);
                          return cartItems.any((i) => i.name == item?.name);
                        }).toList();

                        for (var key in keysToRemove) {
                          await cartBox.delete(key);
                        }

                        if (!context.mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationPage()),
                          (route) => false,
                        );
                      },
                      child: const Text('Checkout Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
