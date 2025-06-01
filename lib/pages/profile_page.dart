import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto profil dari assets
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/profile_picture.jpg'),
            ),
          ),
          const SizedBox(height: 24),

          // Info nama dan NIM
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nama: Resti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'NIM: 123220147',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),

          // Sosial media
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link, color: Colors.pinkAccent),
            title: const Text('Instagram: @restirama_'),
            onTap: () => _launchURL('http://instagram.com/restirama_'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.code, color: Colors.pinkAccent),
            title: const Text('GitHub: resti147'),
            onTap: () => _launchURL('https://github.com/resti147'),
          ),
          const SizedBox(height: 32),

          // Kesan dan Pesan
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kesan & Pesan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mata kuliah ini menarik, adrenalin saya meningkat, gacor, lumayan agak gila!',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
