import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_tpm/model/data_model.dart';

class AppService {
  static const url = 'https://fakestoreapi.com/products';

  static Future<List<ModelApp>> getData() async {
    try {
      final response = await http.get(Uri.parse(url));
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => ModelApp.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
      rethrow;
    }
  }

  static Future<ModelApp> getDataId(int id) async {
    final response = await http.get(Uri.parse("$url/$id"));
    if (response.statusCode == 200) {
      return ModelApp.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}
