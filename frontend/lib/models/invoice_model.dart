import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final String clientName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double total;
  final String status;  // 'draft', 'sent', 'paid', 'overdue'
  final String? projectId;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceModel({
    this.id = '',
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.invoiceDate,
    required this.dueDate,
    required this.lineItems,
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    required this.status,
    this.projectId,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Process line items
    List<InvoiceLineItem> lineItems = [];
    if (data['lineItems'] != null && data['lineItems'] is List) {
      lineItems = (data['lineItems'] as List)
          .map((item) => InvoiceLineItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    
    return InvoiceModel(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      invoiceDate: (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lineItems: lineItems,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatRate: (data['vatRate'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (data['vatAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'draft',
      projectId: data['projectId'],
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'clientName': clientName,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'total': total,
      'status': status,
      if (projectId != null) 'projectId': projectId,
      if (note != null && note!.isNotEmpty) 'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
