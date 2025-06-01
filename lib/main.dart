import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:project_tpm/model/cart_item.dart';
import 'package:project_tpm/model/notification_item.dart';
import 'package:project_tpm/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Daftarkan adapter CartItem
  Hive.registerAdapter(CartItemAdapter());

  // Buka box users dan cart
  await Hive.openBox('users');
  await Hive.openBox<CartItem>('cart_box'); 

  await Hive.openBox<CartItem>('cart_box');
  await Hive.openBox<NotificationItem>('notification_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginPage(),
    );
  }
}
