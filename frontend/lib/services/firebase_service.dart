import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_details.dart';
import 'http_client.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getReadableError(String error) {
    if (error.contains('already in use')) {
      return 'This email address is already registered. Please try logging in or use a different email.';
    }
    if (error.contains('weak-password')) {
      return 'Please use a stronger password with at least 8 characters.';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    return 'An error occurred during registration. Please try again.';
  }

  // Authentication methods blijven in frontend
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('Step 1: Starting registration...'); // Debug log

      // Create user via backend
      print('Step 2: Sending request to backend...'); // Debug log
      final response = await HttpClient.post('/users', {
        'email': email,
        'password': password,
        'fullName': fullName,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Step 3: Backend response received: $response'); // Debug log

      // Wait a bit before trying to sign in
      await Future.delayed(const Duration(seconds: 2));

      // Instead of sending verification email here, we'll use the link from backend
      final verificationLink = response['verificationLink'];
      print('Verification link received: $verificationLink');

      // Sign in with credentials
      print('Step 4: Attempting to sign in...'); // Debug log
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Step 5: Sign in successful'); // Debug log

      return userCredential;
    } catch (e) {
      print('Registration error - Full details: $e'); // Detailed error log
      throw Exception(_getReadableError(e.toString()));
    }
  }

  // Business details gaan via de backend
  Future<void> updateBusinessDetails(String userId, BusinessDetails details) async {
    try {
      await HttpClient.put('/users/$userId/business-details', details.toJson());
    } catch (e) {
      print('Error updating business details: $e');
      rethrow;
    }
  }

  // Banking details gaan via de backend
  Future<void> updateBankingDetails(String userId, Map<String, dynamic> bankingDetails) async {
    try {
      await HttpClient.put('/users/$userId/banking-details', bankingDetails);
    } catch (e) {
      print('Error updating banking details: $e');
      rethrow;
    }
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      return doc.data()?['profile_completed'] ?? false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }
}
