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

      // Probeer eerst direct met Firebase te registreren voor debugging
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Step 2: User created in Firebase Authentication');
      
      // Update display name
      await userCredential.user?.updateDisplayName(fullName);
      
      // Stuur verificatie e-mail
      await userCredential.user?.sendEmailVerification();
      print('Step 3: Verification email sent');
      
      // Maak gebruikersdocument in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': fullName,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending_verification',
            'role': 'user',
            'lastLogin': FieldValue.serverTimestamp(),
            'profile_completed': false,
          });
      print('Step 4: User document created in Firestore');
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

  // Check if Firestore rules are deployed and working
  Future<bool> areFirestoreRulesWorking() async {
    try {
      print('Testing if Firestore rules are properly deployed...');
      
      // Try to write to a test collection that's not in our regular structure
      // This will only succeed if the rules are extremely permissive
      final testRef = FirebaseFirestore.instance.collection('rule_tests').doc('test_doc');
      
      await testRef.set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': 'This is a test to verify rules deployment'
      });
      
      print('Successfully wrote to test collection - rules are VERY permissive!');
      
      // Clean up our test
      await testRef.delete();
      print('Test document cleaned up');
      
      return true;
    } catch (e) {
      print('Failed to write to test collection: $e');
      
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permission denied - rules are not fully permissive yet');
      }
      
      return false;
    }
  }

  // Test Firestore permissions with rule deployment verification
  Future<Map<String, bool>> testFirestorePermissions() async {
    final results = <String, bool>{};
    final user = _auth.currentUser;
    
    print('===== FIRESTORE PERMISSIONS TEST =====');
    print('Testing with user: ${user?.uid ?? "No user"}');
    
    if (user == null) {
      print('No user logged in. Please log in first.');
      return {'authenticated': false};
    }
    
    // First check if rules are deployed correctly
    final rulesWorking = await areFirestoreRulesWorking();
    results['rules_deployed'] = rulesWorking;
    
    if (!rulesWorking) {
      print('\n⚠️ IMPORTANT: Your Firestore rules may not be deployed correctly!');
      print('Please run the deploy_no_auth.bat script from your backend folder.');
      print('The script is located at: backend/deploy_no_auth.bat\n');
    }
    
    try {
      // Test reading user document
      try {
        print('1. Testing read access to user document...');
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();
        results['read_user_doc'] = true;
        results['user_doc_exists'] = docSnapshot.exists;
        
        // Print full document data for debugging
        if (docSnapshot.exists) {
          print('User document data: ${docSnapshot.data()}');
        } else {
          print('User document does not exist - creating it now');
          // Create the user document if it doesn't exist
          await docRef.set({
            'fullName': user.displayName ?? 'User',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          print('User document created successfully');
        }
      } catch (e) {
        results['read_user_doc'] = false;
        print('Error reading user document: $e');
        print('Full error: $e');
      }
      
      // Test creating a test document with detailed logging
      try {
        print('\n2. Testing write access to test document...');
        final testDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tests')
            .doc('permission_test_${DateTime.now().millisecondsSinceEpoch}');
        
        print('Writing test document to: ${testDocRef.path}');
        
        await testDocRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
          'userId': user.uid,
          'testId': DateTime.now().toIso8601String()
        });
        
        print('Test document write successful');
        results['write_test_doc'] = true;
      } catch (e) {
        results['write_test_doc'] = false;
        print('Error writing test document: $e');
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
          print('Firebase error details: ${e.plugin}, ${e.stackTrace}');
        }
      }
      
      // Test creating a project document with detailed logging
      try {
        print('\n3. Testing write access to project document...');
        final projectsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc('test_project_${DateTime.now().millisecondsSinceEpoch}');
        
        print('Writing project document to: ${projectsRef.path}');
        
        await projectsRef.set({
          'title': 'Test Project',
          'description': 'Testing permissions',
          'createdAt': FieldValue.serverTimestamp(),
          'testId': DateTime.now().toIso8601String()
        });
        
        print('Project document write successful');
        results['write_project'] = true;
      } catch (e) {
        results['write_project'] = false;
        print('Error writing project: $e');
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
          print('Firebase error details: ${e.plugin}, ${e.stackTrace}');
        }
      }
      
      print('\n===== TEST RESULTS =====');
      results.forEach((key, value) {
        print('$key: $value');
      });
      
    } catch (e) {
      print('General permission test error: $e');
      results['error'] = true;
    }
    
    return results;
  }
}
