// This is a test-friendly version of the HttpClient that allows injecting a mock client
import 'dart:convert';
import 'package:http/http.dart' as http;

class TestHttpClient {
  static const String _baseUrl = 'http://localhost:3000/api';
  static http.Client? _mockClient;
  
  // Method to set the mock client for testing
  static void setMockClient(http.Client mockClient) {
    _mockClient = mockClient;
  }
  
  // Method to reset the mock client after tests
  static void resetMockClient() {
    _mockClient = null;
  }
  
  // Get the client to use (mock or real)
  static http.Client _getClient() {
    return _mockClient ?? http.Client();
  }
  
  static Future<dynamic> get(String endpoint) async {
    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse(_baseUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
      );
      
      return _processResponse(response);
    } catch (e) {
      print('HTTP GET Error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final client = _getClient();
      final response = await client.post(
        Uri.parse(_baseUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      return _processResponse(response);
    } catch (e) {
      print('HTTP POST Error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final client = _getClient();
      final response = await client.put(
        Uri.parse(_baseUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      return _processResponse(response);
    } catch (e) {
      print('HTTP PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<dynamic> delete(String endpoint) async {
    try {
      final client = _getClient();
      final response = await client.delete(
        Uri.parse(_baseUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
      );
      
      return _processResponse(response);
    } catch (e) {
      print('HTTP DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Check if there's content and parse it
      if (response.body.isEmpty) {
        return {};
      }
      
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('JSON Decode Error: $e');
        return {};
      }
    } else {
      // Handle errors
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['error'] ?? errorMessage;
      } catch (e) {
        // Ignore if cannot parse error message
      }
      
      throw Exception(errorMessage);
    }
  }
}
