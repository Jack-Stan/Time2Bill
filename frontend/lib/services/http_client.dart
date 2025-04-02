import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpClient {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      print('Sending request to: $baseUrl$endpoint'); // Debug log
      print('Request body: $body'); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      }

      throw Exception('Request failed with status: ${response.statusCode}, body: ${response.body}');
    } catch (e) {
      print('HTTP Error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      }

      throw Exception(json.decode(response.body)['error'] ?? 'Request failed');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      }

      throw Exception(json.decode(response.body)['error'] ?? 'Request failed');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
