import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  String? id;
  String title;
  String? clientId;
  String? clientName;
  double hourlyRate;
  DateTime startDate;
  DateTime? endDate;
  String? description;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  ProjectModel({
    this.id,
    required this.title,
    this.clientId,
    this.clientName,
    required this.hourlyRate,
    required this.startDate,
    this.endDate,
    this.description,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });
  
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return ProjectModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Project',
      clientId: data['clientId'] as String?,
      clientName: data['clientName'] as String?,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      description: data['description'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'clientId': clientId,
      'clientName': clientName,
      'hourlyRate': hourlyRate,
      'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'description': description,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }
}
