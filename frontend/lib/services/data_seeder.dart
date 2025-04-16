import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Hulpklasse om testdata te genereren voor de applicatie
class DataSeeder {
  // Controleer of er testdata genereerd moet worden
  static Future<void> seedDataIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Check if we already have data
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .limit(1)
        .get();
    
    final invoicesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .limit(1)
        .get();
        
    final timeEntriesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .limit(1)
        .get();
    
    // Als er al data is, niets doen
    if (projectsSnapshot.docs.isNotEmpty && 
        invoicesSnapshot.docs.isNotEmpty && 
        timeEntriesSnapshot.docs.isNotEmpty) {
      print('Test data already exists, skipping seed');
      return;
    }
    
    // Anders, testdata genereren
    print('No data found, generating test data...');
    await _seedProjects(user.uid);
    await _seedTimeEntries(user.uid);
    await _seedInvoices(user.uid);
    print('Test data generation complete');
  }
  
  // Voeg enkele voorbeeldprojecten toe
  static Future<void> _seedProjects(String userId) async {
    final projectsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('projects');
    
    // Testprojecten
    final projects = [
      {
        'title': 'Website Redesign',
        'client': 'ACME Corporation',
        'description': 'Herontwerp van de bedrijfswebsite met focus op gebruikerservaring',
        'status': 'Active',
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'title': 'Mobiele App Ontwikkeling',
        'client': 'TechSolutions BV',
        'description': 'Ontwikkeling van een iOS en Android applicatie voor projectmanagement',
        'status': 'Active',
        'createdAt': DateTime.now().subtract(const Duration(days: 14)),
      },
      {
        'title': 'E-commerce Platform',
        'client': 'Fashion Store',
        'description': 'Implementatie van een online webshop met betalingsverwerking',
        'status': 'Active',
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      },
    ];
    
    // Batch create projects
    final batch = FirebaseFirestore.instance.batch();
    
    for (final project in projects) {
      final docRef = projectsRef.doc();
      batch.set(docRef, {
        ...project,
        'createdAt': Timestamp.fromDate(project['createdAt'] as DateTime),
      });
    }
    
    await batch.commit();
    print('Created ${projects.length} sample projects');
  }
  
  // Voeg enkele voorbeeld-urenstaten toe
  static Future<void> _seedTimeEntries(String userId) async {
    final timeEntriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('timeTracking');
    
    final today = DateTime.now();
    
    // Test time entries
    final entries = [
      {
        'projectId': 'Website Redesign',
        'description': 'UI Design wireframes',
        'duration': 3 * 3600, // 3 hours in seconds
        'date': today.subtract(const Duration(days: 1)),
        'createdAt': today.subtract(const Duration(days: 1)),
      },
      {
        'projectId': 'Website Redesign',
        'description': 'Frontend development',
        'duration': 5 * 3600, // 5 hours in seconds
        'date': today.subtract(const Duration(days: 2)),
        'createdAt': today.subtract(const Duration(days: 2)),
      },
      {
        'projectId': 'Mobiele App Ontwikkeling',
        'description': 'API integratie',
        'duration': 4 * 3600, // 4 hours in seconds
        'date': today.subtract(const Duration(days: 3)),
        'createdAt': today.subtract(const Duration(days: 3)),
      },
      {
        'projectId': 'Mobiele App Ontwikkeling',
        'description': 'Bug fixes',
        'duration': 2 * 3600, // 2 hours in seconds
        'date': today,
        'createdAt': today,
      },
    ];
    
    // Create time entries
    final batch = FirebaseFirestore.instance.batch();
    
    for (final entry in entries) {
      final docRef = timeEntriesRef.doc();
      batch.set(docRef, {
        ...entry,
        'date': Timestamp.fromDate(entry['date'] as DateTime),
        'createdAt': Timestamp.fromDate(entry['createdAt'] as DateTime),
      });
    }
    
    await batch.commit();
    print('Created ${entries.length} sample time entries');
  }
  
  // Voeg enkele voorbeeld-facturen toe
  static Future<void> _seedInvoices(String userId) async {
    final invoicesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('invoices');
    
    final today = DateTime.now();
    
    // Test invoices
    final invoices = [
      {
        'invoiceNumber': 'INV-2023-001',
        'clientName': 'ACME Corporation',
        'description': 'Website development services',
        'total': 1250.00,
        'status': 'paid',
        'createdAt': today.subtract(const Duration(days: 45)),
        'paymentDate': today.subtract(const Duration(days: 30)),
      },
      {
        'invoiceNumber': 'INV-2023-002',
        'clientName': 'TechSolutions BV',
        'description': 'Consultancy services',
        'total': 850.00,
        'status': 'unpaid',
        'createdAt': today.subtract(const Duration(days: 15)),
        'dueDate': today.add(const Duration(days: 15)),
      },
      {
        'invoiceNumber': 'INV-2023-003',
        'clientName': 'Fashion Store',
        'description': 'E-commerce platform implementation',
        'total': 2450.00,
        'status': 'unpaid',
        'createdAt': today.subtract(const Duration(days: 5)),
        'dueDate': today.add(const Duration(days: 25)),
      },
    ];
    
    // Create invoices
    final batch = FirebaseFirestore.instance.batch();
    
    for (final invoice in invoices) {
      final docRef = invoicesRef.doc();
      final Map<String, dynamic> invoiceData = {...invoice};
      
      invoiceData['createdAt'] = Timestamp.fromDate(invoice['createdAt'] as DateTime);
      
      if (invoice.containsKey('paymentDate')) {
        invoiceData['paymentDate'] = Timestamp.fromDate(invoice['paymentDate'] as DateTime);
      }
      
      if (invoice.containsKey('dueDate')) {
        invoiceData['dueDate'] = Timestamp.fromDate(invoice['dueDate'] as DateTime);
      }
      
      batch.set(docRef, invoiceData);
    }
    
    await batch.commit();
    print('Created ${invoices.length} sample invoices');
  }
}
