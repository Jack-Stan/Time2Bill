import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> updateBusinessDetails({
    required String userId,
    required String companyName,
    required String vatNumber,
    required String address,
    String? peppolId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'businessDetails': {
        'companyName': companyName,
        'vatNumber': vatNumber,
        'address': address,
        'peppolId': peppolId,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    });
  }
}
