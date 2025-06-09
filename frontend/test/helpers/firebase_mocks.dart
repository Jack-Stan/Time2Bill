// Helper file to generate mocks for Firebase tests
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

// This generates mocks for these classes
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  UserCredential,
], customMocks: [
  MockSpec<DocumentReference>(as: #MockDocumentRef),
  MockSpec<CollectionReference>(as: #MockCollectionRef),
  MockSpec<DocumentSnapshot>(as: #MockDocumentSnap),
  MockSpec<QuerySnapshot>(as: #MockQuerySnap),
])
void main() {}

/// A custom mock for DocumentSnapshot to be used in tests
/// This can be used directly in tests where we need to simulate a DocumentSnapshot
/// without using the sealed class
class TestDocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  TestDocumentSnapshot(this._id, this._data);

  String get id => _id;
  Map<String, dynamic> data() => _data;
}
