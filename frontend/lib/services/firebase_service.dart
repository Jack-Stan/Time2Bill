import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_details.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/invoice_model.dart';
import '../models/time_entry_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      
      // Save user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': fullName.split(' ').first,
        'lastName': fullName.contains(' ') ? fullName.split(' ').sublist(1).join(' ') : '',
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message;
      
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      
      throw Exception(message);
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Invalid password';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      
      throw Exception(message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // User data methods
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('users').doc(user.uid).update({
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null) 'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        print('User document not found');
        return false;
      }
      
      final data = doc.data() ?? {};
      
      // Controleer of alle verplichte velden aanwezig zijn
      final requiredFields = [
        'firstName', 
        'lastName',
        'businessName',
        'vatNumber',
        'address'
      ];
      
      for (final field in requiredFields) {
        if (data[field] == null || data[field].toString().isEmpty) {
          print('Incomplete profile: missing $field');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Error checking profile completeness: $e');
      return false;
    }
  }

  Future<void> updateBusinessDetails(
    String userId, 
    BusinessDetails businessDetails
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'businessName': businessDetails.companyName,
      'vatNumber': businessDetails.vatNumber,
      'address': businessDetails.address,
      'defaultVatRate': businessDetails.defaultVatRate,
      'paymentTerms': businessDetails.paymentTerms,
      'peppolId': businessDetails.peppolId,
      'phone': businessDetails.phone,
      'website': businessDetails.website,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Clients methods
  Future<List<ClientModel>> getClients() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => ClientModel.fromFirestore(doc))
        .toList();
  }

  Future<ClientModel> getClient(String clientId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(clientId)
        .get();

    if (!doc.exists) {
      throw Exception('Client not found');
    }

    return ClientModel.fromFirestore(doc);
  }

  Future<String> addClient(ClientModel client) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .add(client.toMap());

    return docRef.id;
  }

  Future<void> updateClient(String clientId, ClientModel client) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(clientId)
        .update(client.toMap());
  }

  Future<void> deleteClient(String clientId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(clientId)
        .delete();
  }

  // Projects methods
  Future<List<ProjectModel>> getProjects() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .get();

      // Ook de clientnamen voor elk project laden
      final projects = await Future.wait(snapshot.docs.map((doc) async {
        final projectData = doc.data();
        final clientId = projectData['clientId'] as String?;
        String? clientName;
        
        // Als er een clientId is, haal dan de naam van de client op
        if (clientId != null && clientId.isNotEmpty) {
          try {
            final clientDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('clients')
                .doc(clientId)
                .get();
                
            if (clientDoc.exists) {
              final clientData = clientDoc.data() as Map<String, dynamic>?;
              clientName = clientData?['name'] as String?;
            }
          } catch (e) {
            print('Error fetching client name for project ${doc.id}: $e');
          }
        }
        
        // Maak ProjectModel met echte data
        final project = ProjectModel.fromFirestore(doc);
        if (clientName != null) {
          project.clientName = clientName;
        }
        
        return project;
      }));

      return projects;
    } catch (e) {
      print('Error loading projects: $e');
      throw Exception('Failed to load projects: $e');
    }
  }

  Future<ProjectModel> getProject(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .get();

    if (!doc.exists) {
      throw Exception('Project not found');
    }

    return ProjectModel.fromFirestore(doc);
  }

  Future<String> addProject(ProjectModel project) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .add(project.toMap());

    return docRef.id;
  }

  Future<void> updateProject(String projectId, ProjectModel project) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .update(project.toMap());
  }

  Future<void> deleteProject(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  // Invoices methods
  Future<List<InvoiceModel>> getInvoices({String? status}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .orderBy('invoiceDate', descending: true);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    try {
      final snapshot = await query.get();
      
      print('Fetched ${snapshot.docs.length} invoices from Firestore');
      
      // Log details of the first 2 invoices for debugging with null safety
      if (snapshot.docs.isNotEmpty) {
        try {
          final firstData = snapshot.docs.first.data() as Map<String, dynamic>?;
          final firstInvoiceNumber = firstData?['invoiceNumber'] ?? 'No number';
          final firstTotal = firstData?['total'] ?? 'No total';
          print('First invoice: $firstInvoiceNumber - $firstTotal');
          
          if (snapshot.docs.length > 1) {
            final secondData = snapshot.docs[1].data() as Map<String, dynamic>?;
            final secondInvoiceNumber = secondData?['invoiceNumber'] ?? 'No number';
            final secondTotal = secondData?['total'] ?? 'No total';
            print('Second invoice: $secondInvoiceNumber - $secondTotal');
          }
        } catch (e) {
          print('Error parsing invoice data: $e');
        }
      }

      return snapshot.docs
          .map((doc) => InvoiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching invoices: $e');
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  Future<InvoiceModel> getInvoice(String invoiceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (!doc.exists) {
        throw Exception('Invoice not found');
      }

      return InvoiceModel.fromFirestore(doc);
    } catch (e) {
      print('Error fetching invoice $invoiceId: $e');
      throw Exception('Failed to fetch invoice details: $e');
    }
  }

  Future<String> addInvoice(InvoiceModel invoice) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final invoiceData = invoice.toMap();
      print('Adding invoice to Firebase: ${invoice.invoiceNumber}');
      print('Invoice data: $invoiceData');
      
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .add(invoiceData);
          
      print('Invoice added successfully with ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('Error adding invoice: $e');
      throw Exception('Failed to add invoice: $e');
    }
  }

  Future<void> updateInvoice(String invoiceId, InvoiceModel invoice) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('Updating invoice $invoiceId in Firebase');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .update(invoice.toMap());
          
      print('Invoice updated successfully');
    } catch (e) {
      print('Error updating invoice: $e');
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String newStatus) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('Updating invoice $invoiceId status to: $newStatus');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
      print('Invoice status updated successfully');
    } catch (e) {
      print('Error updating invoice status: $e');
      throw Exception('Failed to update invoice status: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('Deleting invoice $invoiceId from Firebase');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .delete();
          
      print('Invoice deleted successfully');
    } catch (e) {
      print('Error deleting invoice: $e');
      throw Exception('Failed to delete invoice: $e');
    }
  }

  // Time tracking methods
  Future<List<TimeEntryModel>> getTimeEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? projectId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .orderBy('startTime', descending: true);

    if (startDate != null) {
      query = query.where('startTime', 
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('startTime', 
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => TimeEntryModel.fromFirestore(doc))
        .toList();
  }

  Future<TimeEntryModel> getTimeEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .doc(entryId)
        .get();

    if (!doc.exists) {
      throw Exception('Time entry not found');
    }

    return TimeEntryModel.fromFirestore(doc);
  }

  Future<String> addTimeEntry(TimeEntryModel entry) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .add(entry.toMap());

    return docRef.id;
  }

  Future<void> updateTimeEntry(String entryId, TimeEntryModel entry) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .doc(entryId)
        .update(entry.toMap());
  }

  Future<void> deleteTimeEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timeTracking')
        .doc(entryId)
        .delete();
  }

  // Test Firebase permissions
  Future<Map<String, bool>> testFirestorePermissions() async {
    final results = <String, bool>{};
    final user = _auth.currentUser;
    
    if (user == null) {
      results['authenticated'] = false;
      return results;
    }
    
    results['authenticated'] = true;
    
    try {
      // Test user document read
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      results['read_user_doc'] = userDoc.exists;
    } catch (e) {
      results['read_user_doc'] = false;
    }
    
    try {
      // Test write to user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({'lastActive': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      results['write_user_doc'] = true;
    } catch (e) {
      results['write_user_doc'] = false;
    }
    
    try {
      // Test client collection access
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .limit(1)
          .get();
      results['access_clients'] = true;
    } catch (e) {
      results['access_clients'] = false;
    }
    
    try {
      // Test projects collection access
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .limit(1)
          .get();
      results['access_projects'] = true;
    } catch (e) {
      results['access_projects'] = false;
    }
    
    try {
      // Test invoices collection access
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .limit(1)
          .get();
      results['access_invoices'] = true;
    } catch (e) {
      results['access_invoices'] = false;
    }
    
    try {
      // Test time tracking collection access
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('timeTracking')
          .limit(1)
          .get();
      results['access_time_tracking'] = true;
    } catch (e) {
      results['access_time_tracking'] = false;
    }
    
    return results;
  }
}
