import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:project_tpm/model/notification_item.dart';
import 'package:project_tpm/pages/home_page.dart';
import 'package:project_tpm/pages/profile_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage(username: 'User')),
        );
        break;
      case 1:
        // Sudah di NotificationPage, tidak perlu apa-apa
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(221, 246, 74, 148),
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
                      child: const Text('Hapus'),
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
      body: ValueListenableBuilder(
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
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Metode: ${notif.paymentMethod.isNotEmpty ? notif.paymentMethod : '-'}",
                              style: const TextStyle(
                                color: Colors.pinkAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${notif.timestamp.toLocal()}'.split('.')[0],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // posisi Notifikasi
        selectedItemColor: Colors.pink,
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
