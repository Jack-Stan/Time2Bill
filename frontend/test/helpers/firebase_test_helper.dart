import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up method channel mocks
  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
  const MethodChannel authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
  const MethodChannel firestoreChannel = MethodChannel('plugins.flutter.io/cloud_firestore');

  // Setup Firebase Core
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'messagingSenderId': 'test-sender-id',
                'projectId': 'test-project-id',
                'databaseURL': 'test-database-url',
                'storageBucket': 'test-bucket',
              },
              'pluginConstants': {},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project-id',
              'databaseURL': 'test-database-url',
              'storageBucket': 'test-bucket',
            },
            'pluginConstants': {},
          };
        default:
          return null;
      }
    },
  );

  // Setup Auth
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    authChannel,
    (call) async {
      switch (call.method) {
        case 'Auth#registerIdTokenListener':
        case 'Auth#registerAuthStateListener':
          return {'listen': true};
        default:
          return null;
      }
    },
  );

  // Setup Firestore
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    firestoreChannel,
    (call) async {
      switch (call.method) {
        case 'Firestore#enablePersistence':
          return true;
        case 'Firestore#settings':
          return true;
        case 'DocumentReference#get':
          return {
            'data': {},
            'metadata': {'hasPendingWrites': false, 'isFromCache': false},
            'path': call.arguments['path'],
          };
        case 'Query#get':
          return {
            'documents': [],
            'metadata': {'hasPendingWrites': false, 'isFromCache': false},
          };
        default:
          return null;
      }
    },
  );

  // Initialize Firebase
  await Firebase.initializeApp();
}
