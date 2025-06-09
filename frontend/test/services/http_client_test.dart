import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/test_http_client.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';

@GenerateMocks([http.Client])
import 'http_client_test.mocks.dart';

void main() {
  group('HttpClient Tests', () {
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      TestHttpClient.setMockClient(mockHttpClient);
    });

    tearDown(() {
      TestHttpClient.resetMockClient();
    });

    test('GET request returns data when response is successful', () async {
      // Arrange
      final responseData = {'success': true, 'data': {'name': 'Test'}};
      
      when(mockHttpClient.get(
        Uri.parse('http://localhost:3000/api/test'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => 
        http.Response(json.encode(responseData), 200));
      
      // Act & Assert
      expect(await TestHttpClient.get('/test'), equals(responseData));
    });

    test('GET request throws exception when response is not successful', () async {
      // Arrange
      when(mockHttpClient.get(
        Uri.parse('http://localhost:3000/api/test'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => 
        http.Response('{"error": "Not found"}', 404));
      
      // Act & Assert
      expect(() => TestHttpClient.get('/test'), throwsException);
    });

    test('POST request returns data when response is successful', () async {
      // Arrange
      final requestData = {'name': 'Test'};
      final responseData = {'success': true, 'data': {'id': 1, 'name': 'Test'}};
      
      when(mockHttpClient.post(
        Uri.parse('http://localhost:3000/api/test'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => 
        http.Response(json.encode(responseData), 201));
      
      // Act & Assert
      expect(await TestHttpClient.post('/test', requestData), equals(responseData));
    });

    test('POST request throws exception when response is not successful', () async {
      // Arrange
      final requestData = {'name': 'Test'};
      
      when(mockHttpClient.post(
        Uri.parse('http://localhost:3000/api/test'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => 
        http.Response('{"error": "Bad request"}', 400));
      
      // Act & Assert
      expect(() => TestHttpClient.post('/test', requestData), throwsException);
    });

    test('PUT request returns data when response is successful', () async {
      // Arrange
      final requestData = {'id': 1, 'name': 'Updated'};
      final responseData = {'success': true, 'data': {'id': 1, 'name': 'Updated'}};
      
      when(mockHttpClient.put(
        Uri.parse('http://localhost:3000/api/test/1'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => 
        http.Response(json.encode(responseData), 200));
      
      // Act & Assert
      expect(await TestHttpClient.put('/test/1', requestData), equals(responseData));
    });

    test('DELETE request returns success when response is successful', () async {
      // Arrange
      final responseData = {'success': true};
      
      when(mockHttpClient.delete(
        Uri.parse('http://localhost:3000/api/test/1'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => 
        http.Response(json.encode(responseData), 200));
      
      // Act & Assert      expect(await TestHttpClient.delete('/test/1'), equals(responseData));
    });
  });
}
