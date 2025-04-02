import 'business_details.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;
  BusinessDetails? businessDetails;
  String status;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.businessDetails,
    this.status = 'pending_verification',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'createdAt': createdAt.toIso8601String(),
        'businessDetails': businessDetails?.toJson(),
        'status': status,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        fullName: json['fullName'],
        createdAt: json['createdAt'].toDate(),
        businessDetails: json['businessDetails'] != null
            ? BusinessDetails.fromJson(json['businessDetails'])
            : null,
        status: json['status'] ?? 'pending_verification',
      );
}
