import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:project_tpm/model/notification_item.dart';
import 'package:project_tpm/pages/home_page.dart';
import 'package:project_tpm/pages/profile_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String selectedZone = 'WIB';

  Duration _getOffset(String zone) {
    switch (zone) {
      case 'WITA':
        return const Duration(hours: 1);
      case 'WIT':
        return const Duration(hours: 2);
      case 'London':
        return const Duration(hours: -6); // WIB - 7 (WIB UTC+7 -> London UTC+1)
      case 'WIB':
      default:
        return Duration.zero;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final offset = _getOffset(selectedZone);
    final adjusted = timestamp.add(offset);

    return '${adjusted.toLocal()}'.split('.')[0];
  }

  void _onItemTapped(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    switch (index) {
      case 0:
        if (currentRoute != '/home') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(username: 'User'),
              settings: const RouteSettings(name: '/home'),
            ),
          );
        }
        break;
      case 1:
        break;
      case 2:
        if (currentRoute != '/profile') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilePage(),
              settings: const RouteSettings(name: '/profile'),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 166, 192, 235),
      appBar: AppBar(
        title: const Text('Notification', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 14, 61, 127),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              final notifBox = Hive.box<NotificationItem>('notification_box');
              if (notifBox.isEmpty) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Semua Notifikasi?'),
                  content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                  actions: [
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Hapus', style: TextStyle(color: Colors.red),),
                      onPressed: () {
                        notifBox.clear();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Time Zone',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  dropdownColor: Color.fromARGB(255, 216, 229, 247),
                  value: selectedZone,
                  onChanged: (value) {
                    setState(() {
                      selectedZone = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'WIB', child: Text('WIB')),
                    DropdownMenuItem(value: 'WITA', child: Text('WITA')),
                    DropdownMenuItem(value: 'WIT', child: Text('WIT')),
                    DropdownMenuItem(value: 'London', child: Text('London')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<NotificationItem>('notification_box').listenable(),
              builder: (context, Box<NotificationItem> notifBox, _) {
                final notifs = notifBox.values.toList().reversed.toList();

                if (notifs.isEmpty) {
                  return const Center(child: Text('Belum ada notifikasi.'));
                }

                return ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final notif = notifs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFE6E6FA)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.message,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Metode: ${notif.paymentMethod.isNotEmpty ? notif.paymentMethod : '-'}",
                                    style: const TextStyle(color: Color.fromARGB(255, 14, 61, 127)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(notif.timestamp),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color.fromARGB(255, 14, 61, 127),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
