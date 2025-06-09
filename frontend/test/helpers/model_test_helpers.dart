// Test helpers for models
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/client_model.dart';
import 'package:frontend/models/invoice_model.dart';
import 'firebase_mocks.dart';

/// Extensions on TestDocumentSnapshot to create models for testing
extension ClientModelFromTest on TestDocumentSnapshot {
  /// Create a ClientModel from this test document snapshot
  ClientModel toClientModel() {
    final data = this.data();
    
    return ClientModel(
      id: id,
      name: data['name'] ?? '',
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      postalCode: data['postalCode'] ?? '',
      vatNumber: data['vatNumber'],
      contactPerson: data['contactPerson'] ?? '',
      notes: data['notes'] ?? '',
      peppolId: data['peppolId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  /// Create an InvoiceModel from this test document snapshot
  InvoiceModel toInvoiceModel() {
    final data = this.data();
    
    // Process line items
    List<InvoiceLineItem> lineItems = [];
    if (data['lineItems'] != null && data['lineItems'] is List) {
      lineItems = (data['lineItems'] as List)
          .map((item) => InvoiceLineItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    
    return InvoiceModel(
      id: id,
      invoiceNumber: data['invoiceNumber']?.toString() ?? '',
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      invoiceDate: (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lineItems: lineItems,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatRate: (data['vatRate'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (data['vatAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'draft',
      projectId: data['projectId']?.toString(),
      note: data['note']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
