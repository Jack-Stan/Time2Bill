import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String postalCode;
  final String? vatNumber;
  final String contactPerson;
  final String notes;
  final String? peppolId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  ClientModel({
    this.id = '',
    required this.name,
    this.companyName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.postalCode = '',
    this.vatNumber,
    this.contactPerson = '',
    this.notes = '',
    this.peppolId,
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
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'companyName': companyName,
      'city': city,
      'postalCode': postalCode,
      if (peppolId != null) 'peppolId': peppolId,
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
