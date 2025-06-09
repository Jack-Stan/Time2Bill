import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/invoice_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/model_test_helpers.dart';
import '../helpers/firebase_mocks.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('InvoiceLineItem Tests', () {
    test('should create an InvoiceLineItem with all properties', () {
      // Arrange & Act
      final lineItem = InvoiceLineItem(
        description: 'Consulting Services',
        quantity: 10,
        unitPrice: 50.0,
        amount: 500.0,
      );

      // Assert
      expect(lineItem.description, 'Consulting Services');
      expect(lineItem.quantity, 10);
      expect(lineItem.unitPrice, 50.0);
      expect(lineItem.amount, 500.0);
    });

    test('should convert from map correctly', () {
      // Arrange
      final map = {
        'description': 'Development Hours',
        'quantity': 8,
        'unitPrice': 75.0,
        'amount': 600.0,
      };

      // Act
      final lineItem = InvoiceLineItem.fromMap(map);

      // Assert
      expect(lineItem.description, 'Development Hours');
      expect(lineItem.quantity, 8);
      expect(lineItem.unitPrice, 75.0);
      expect(lineItem.amount, 600.0);
    });

    test('should handle null values when converting from map', () {
      // Arrange
      final map = <String, dynamic>{};

      // Act
      final lineItem = InvoiceLineItem.fromMap(map);

      // Assert
      expect(lineItem.description, '');
      expect(lineItem.quantity, 0);
      expect(lineItem.unitPrice, 0);
      expect(lineItem.amount, 0);
    });

    test('should convert to map correctly', () {
      // Arrange
      final lineItem = InvoiceLineItem(
        description: 'Project Management',
        quantity: 5,
        unitPrice: 90.0,
        amount: 450.0,
      );

      // Act
      final map = lineItem.toMap();

      // Assert
      expect(map['description'], 'Project Management');
      expect(map['quantity'], 5);
      expect(map['unitPrice'], 90.0);
      expect(map['amount'], 450.0);
    });
  });

  group('InvoiceModel Tests', () {
    test('should create an InvoiceModel with all required properties', () {
      // Arrange
      final invoiceDate = DateTime(2025, 6, 1);
      final dueDate = DateTime(2025, 6, 30);
      final lineItems = [
        InvoiceLineItem(
          description: 'Design Work',
          quantity: 10,
          unitPrice: 80.0,
          amount: 800.0,
        ),
      ];

      // Act
      final invoice = InvoiceModel(
        invoiceNumber: 'INV-2025-001',
        clientId: 'client-123',
        clientName: 'ACME Inc.',
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        lineItems: lineItems,
        subtotal: 800.0,
        vatRate: 21.0,
        vatAmount: 168.0,
        total: 968.0,
        status: 'draft',
      );

      // Assert
      expect(invoice.id, '');
      expect(invoice.invoiceNumber, 'INV-2025-001');
      expect(invoice.clientId, 'client-123');
      expect(invoice.clientName, 'ACME Inc.');
      expect(invoice.invoiceDate, invoiceDate);
      expect(invoice.dueDate, dueDate);
      expect(invoice.lineItems, lineItems);
      expect(invoice.subtotal, 800.0);
      expect(invoice.vatRate, 21.0);
      expect(invoice.vatAmount, 168.0);
      expect(invoice.total, 968.0);
      expect(invoice.status, 'draft');
      expect(invoice.projectId, null);
      expect(invoice.note, null);
      expect(invoice.createdAt, null);
      expect(invoice.updatedAt, null);
    });

    test('should convert from Firestore document', () {
      // Arrange
      final invoiceDate = DateTime(2025, 6, 1);
      final dueDate = DateTime(2025, 6, 30);
      final createdAt = DateTime(2025, 6, 1, 10, 30, 0);
      final updatedAt = DateTime(2025, 6, 2, 14, 45, 0);

      final mockData = {
        'invoiceNumber': 'INV-2025-002',
        'clientId': 'client-456',
        'clientName': 'Tech Solutions',
        'invoiceDate': Timestamp.fromDate(invoiceDate),
        'dueDate': Timestamp.fromDate(dueDate),
        'lineItems': [
          {
            'description': 'Web Development',
            'quantity': 20,
            'unitPrice': 70.0,
            'amount': 1400.0,
          },
          {
            'description': 'UI Design',
            'quantity': 5,
            'unitPrice': 90.0,
            'amount': 450.0,
          },
        ],
        'subtotal': 1850.0,
        'vatRate': 21.0,
        'vatAmount': 388.5,
        'total': 2238.5,
        'status': 'sent',
        'projectId': 'project-123',
        'note': 'Please pay within 30 days',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
      
      final testDoc = TestDocumentSnapshot('invoice-123', mockData);
      
      // Act
      // Create an InvoiceModel using our test helper
      final invoice = testDoc.toInvoiceModel();
      
      // Assert
      expect(invoice.id, 'invoice-123');
      expect(invoice.invoiceNumber, 'INV-2025-002');
      expect(invoice.clientId, 'client-456');
      expect(invoice.clientName, 'Tech Solutions');
      expect(invoice.invoiceDate, invoiceDate);
      expect(invoice.dueDate, dueDate);
      expect(invoice.lineItems.length, 2);
      expect(invoice.lineItems[0].description, 'Web Development');
      expect(invoice.lineItems[1].description, 'UI Design');
      expect(invoice.subtotal, 1850.0);
      expect(invoice.vatRate, 21.0);
      expect(invoice.vatAmount, 388.5);
      expect(invoice.total, 2238.5);
      expect(invoice.status, 'sent');
      expect(invoice.projectId, 'project-123');
      expect(invoice.note, 'Please pay within 30 days');
      expect(invoice.createdAt, createdAt);
      expect(invoice.updatedAt, updatedAt);
    });

    test('should convert to map correctly', () {
      // Arrange
      final invoiceDate = DateTime(2025, 6, 1);
      final dueDate = DateTime(2025, 6, 30);
      final createdAt = DateTime(2025, 6, 1, 10, 30, 0);
      final updatedAt = DateTime(2025, 6, 2, 14, 45, 0);
      
      final invoice = InvoiceModel(
        id: 'invoice-789',
        invoiceNumber: 'INV-2025-003',
        clientId: 'client-789',
        clientName: 'Global Services',
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        lineItems: [
          InvoiceLineItem(
            description: 'Consulting',
            quantity: 15,
            unitPrice: 100.0,
            amount: 1500.0,
          ),
        ],
        subtotal: 1500.0,
        vatRate: 21.0,
        vatAmount: 315.0,
        total: 1815.0,
        status: 'paid',
        projectId: 'project-456',
        note: 'Thank you for your business',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Act
      final map = invoice.toMap();

      // Assert
      expect(map['invoiceNumber'], 'INV-2025-003');
      expect(map['clientId'], 'client-789');
      expect(map['clientName'], 'Global Services');
      expect(map['invoiceDate'], isA<Timestamp>());
      expect(map['dueDate'], isA<Timestamp>());
      expect(map['lineItems'], isA<List>());
      expect(map['lineItems'].length, 1);
      expect(map['subtotal'], 1500.0);
      expect(map['vatRate'], 21.0);
      expect(map['vatAmount'], 315.0);
      expect(map['total'], 1815.0);
      expect(map['status'], 'paid');
      expect(map['projectId'], 'project-456');
      expect(map['note'], 'Thank you for your business');
      expect(map['updatedAt'], isA<FieldValue>());
      // createdAt should not be present since it's already set
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('should handle empty document data', () {
      // Arrange
      final emptyData = <String, dynamic>{};
      final testDoc = TestDocumentSnapshot('empty-invoice', emptyData);
      
      // Act
      // Create a custom InvoiceModel for empty data using our helper
      final invoice = testDoc.toInvoiceModel();
      
      // Assert
      expect(invoice.id, 'empty-invoice');
      expect(invoice.invoiceNumber, '');
      expect(invoice.clientId, '');
      expect(invoice.clientName, '');
      expect(invoice.lineItems, isEmpty);
      expect(invoice.subtotal, 0.0);
      expect(invoice.vatRate, 0.0);
      expect(invoice.vatAmount, 0.0);
      expect(invoice.total, 0.0);
      expect(invoice.status, 'draft');
    });
  });
}
