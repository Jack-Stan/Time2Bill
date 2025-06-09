import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('FirebaseService Tests', () {
    test('FirebaseService should initialize without errors', () {
      // This test verifies that Firebase is properly initialized for tests
      expect(() => FirebaseService(), returnsNormally);
    });
  });
}
