import 'package:flutter/material.dart';
import 'package:project_tpm/model/data_model.dart';
import 'package:project_tpm/service/data_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPage extends StatefulWidget {
  final int id;
  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<ModelApp> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = AppService.getDataId(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ModelApp>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 166, 192, 235),
            appBar: AppBar(
              title: const Text(
                'Detail Product',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: Color.fromARGB(255, 14, 61, 127),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else if (snapshot.hasData) {
          final product = snapshot.data!;

          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 166, 192, 235),
            appBar: AppBar(
              title: const Text(
                'Detail Product',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: Color.fromARGB(255, 14, 61, 127),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _buildDetail(product),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 166, 192, 235),
            appBar: AppBar(
              title: const Text(
                'Detail Product',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: Color.fromARGB(255, 14, 61, 127),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDetail(ModelApp product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.image ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 60),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.title ?? 'No Title',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow("Category", product.category ?? '-'),
          _buildDetailRow(
            "Price",
            "\$${product.price?.toStringAsFixed(2) ?? '-'}",
          ),
          _buildDetailRow("Rating", "${product.rating?.rate ?? 0}"),
          const SizedBox(height: 12),
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(product.description ?? '-'),
          const SizedBox(height: 20),
          if (product.image != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.link, color: Colors.white),
                label: const Text(
                  "Open Image in Browser",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final url = Uri.parse(product.image!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    _showSnackbar("URL tidak valid");
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
