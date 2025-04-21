import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String vatNumber;
  final String contactPerson;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientModel({
    this.id = '',
    required this.name,
    this.companyName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.vatNumber = '',
    this.contactPerson = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return ClientModel(
      id: doc.id,
      name: data['name'] ?? '',
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      vatNumber: data['vatNumber'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'companyName': companyName,
      'email': email,
      'phone': phone,
      'address': address,
      'vatNumber': vatNumber,
      'contactPerson': contactPerson,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
