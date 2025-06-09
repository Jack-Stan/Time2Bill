import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/client_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/model_test_helpers.dart';
import '../helpers/firebase_mocks.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('ClientModel Tests', () {
    test('should create a ClientModel with default values', () {
      final client = ClientModel(name: 'Test Client');
      
      expect(client.id, '');
      expect(client.name, 'Test Client');
      expect(client.companyName, '');
      expect(client.email, '');
      expect(client.phone, '');
      expect(client.address, '');
      expect(client.city, '');
      expect(client.postalCode, '');
      expect(client.vatNumber, null);
      expect(client.contactPerson, '');
      expect(client.notes, '');
      expect(client.peppolId, null);
      expect(client.createdAt, null);
      expect(client.updatedAt, null);
    });

    test('should create a ClientModel with all properties', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      final client = ClientModel(
        id: 'client-123',
        name: 'John Doe',
        companyName: 'ACME Inc.',
        email: 'john@example.com',
        phone: '+1234567890',
        address: '123 Main St',
        city: 'New York',
        postalCode: '10001',
        vatNumber: 'VAT12345',
        contactPerson: 'Jane Smith',
        notes: 'Important client',
        peppolId: 'PEPPOL123',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      expect(client.id, 'client-123');
      expect(client.name, 'John Doe');
      expect(client.companyName, 'ACME Inc.');
      expect(client.email, 'john@example.com');
      expect(client.phone, '+1234567890');
      expect(client.address, '123 Main St');
      expect(client.city, 'New York');
      expect(client.postalCode, '10001');
      expect(client.vatNumber, 'VAT12345');
      expect(client.contactPerson, 'Jane Smith');
      expect(client.notes, 'Important client');
      expect(client.peppolId, 'PEPPOL123');
      expect(client.createdAt, createdAt);
      expect(client.updatedAt, updatedAt);
    });

    test('should convert from Firestore correctly', () {      
      final json = {
        'name': 'John Doe',
        'companyName': 'ACME Inc.',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'address': '123 Main St',
        'city': 'New York',
        'postalCode': '10001',
        'vatNumber': 'VAT12345',
        'contactPerson': 'Jane Smith',
        'notes': 'Important client',
        'peppolId': 'PEPPOL123',
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2023, 1, 2)),
      };
      
      // Use our custom function instead of calling fromFirestore directly
      final testDoc = TestDocumentSnapshot('client-123', json);
      final client = testDoc.toClientModel();
      
      expect(client.id, 'client-123');
      expect(client.name, 'John Doe');
      expect(client.companyName, 'ACME Inc.');
      expect(client.email, 'john@example.com');
      expect(client.phone, '+1234567890');
      expect(client.address, '123 Main St');
      expect(client.city, 'New York');
      expect(client.postalCode, '10001');
      expect(client.vatNumber, 'VAT12345');
      expect(client.contactPerson, 'Jane Smith');
      expect(client.notes, 'Important client');
      expect(client.peppolId, 'PEPPOL123');
      expect(client.createdAt, DateTime(2023, 1, 1));
      expect(client.updatedAt, DateTime(2023, 1, 2));
    });

    test('should convert to Map correctly', () {
      final createdAt = DateTime(2023, 1, 1);
      final updatedAt = DateTime(2023, 1, 2);
      
      final client = ClientModel(
        id: 'client-123',
        name: 'John Doe',
        companyName: 'ACME Inc.',
        email: 'john@example.com',
        phone: '+1234567890',
        address: '123 Main St',
        city: 'New York',
        postalCode: '10001',
        vatNumber: 'VAT12345',
        contactPerson: 'Jane Smith',
        notes: 'Important client',
        peppolId: 'PEPPOL123',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final map = client.toMap();
      
      expect(map['name'], 'John Doe');
      expect(map['companyName'], 'ACME Inc.');
      expect(map['email'], 'john@example.com');
      expect(map['phone'], '+1234567890');
      expect(map['address'], '123 Main St');
      expect(map['city'], 'New York');
      expect(map['postalCode'], '10001');
      expect(map['vatNumber'], 'VAT12345');
      expect(map['contactPerson'], 'Jane Smith');
      expect(map['notes'], 'Important client');
      expect(map['peppolId'], 'PEPPOL123');
      expect(map['updatedAt'], isA<FieldValue>());
    });
  });
}
