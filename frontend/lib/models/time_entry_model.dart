import 'package:cloud_firestore/cloud_firestore.dart';

class TimeEntryModel {
  final String id;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final double duration; // In seconds
  final String? projectId;
  final String? projectName;
  final String? clientId;
  final String? clientName;
  final bool billable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimeEntryModel({
    this.id = '',
    required this.description,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.projectId,
    this.projectName,
    this.clientId,
    this.clientName,
    this.billable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return TimeEntryModel(
      id: doc.id,
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      duration: (data['duration'] as num?)?.toDouble() ?? 0.0,
      projectId: data['projectId'],
      projectName: data['projectName'],
      clientId: data['clientId'],
      clientName: data['clientName'],
      billable: data['billable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'duration': duration,
      if (projectId != null) 'projectId': projectId,
      if (projectName != null) 'projectName': projectName,
      if (clientId != null) 'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      'billable': billable,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
