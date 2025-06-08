import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/business_details.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/invoice_model.dart';
import '../models/time_entry_model.dart';
import '../models/email_settings.dart';
import 'pdf_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PdfService _pdfService = PdfService();
  
  // Base URL for API calls - adjust this based on your deployment
  final String _baseUrl = 'http://localhost:3000/api';  // For local development

  // Method to send invoice email
  Future<bool> sendInvoiceEmail({
    required InvoiceModel invoice,
    required String recipientEmail,
    String? customMessage,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get business details for PDF generation
      final businessDetails = await getBusinessDetails();
      
      // Generate PDF and encode to base64
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice: invoice,
        businessDetails: businessDetails,
      );
      final pdfBase64 = base64Encode(pdfBytes);
      final fileName = 'factuur_${invoice.invoiceNumber}.pdf';
      
      // Send email with proper error handling
      final response = await http.post(
        Uri.parse('$_baseUrl/send-invoice-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}'
        },
        body: jsonEncode({
          'invoiceId': invoice.id,
          'recipientEmail': recipientEmail,
          'subject': 'Invoice ${invoice.invoiceNumber} from ${businessDetails.companyName}',
          'message': customMessage ?? 'Please find your invoice attached.',
          'attachment': {
            'content': pdfBase64,
            'filename': fileName,
            'contentType': 'application/pdf'
          }
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Update invoice status to sent
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('invoices')
            .doc(invoice.id)
            .update({
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending invoice email: $e');
      return false; // Return false on error
    }
  }
    // Get business details from Firestore
  Future<BusinessDetails> getBusinessDetails() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!doc.exists) {
      return BusinessDetails(
        companyName: '',
        kboNumber: '',
        vatNumber: '',
        address: '',
        legalForm: '',
        iban: '',
        defaultVatRate: 21,
        paymentTerms: 30,
      );
    }
    
    final data = doc.data() as Map<String, dynamic>;
    
    return BusinessDetails(
      companyName: data['businessName'] ?? '',
      kboNumber: data['kboNumber'] ?? '',
      vatNumber: data['vatNumber'] ?? '',
      address: data['address'] ?? '',
      legalForm: data['legalForm'] ?? '',
      iban: data['iban'] ?? '',
      defaultVatRate: data['defaultVatRate'] ?? 21,
      paymentTerms: data['paymentTerms'] ?? 30,
      peppolId: data['peppolId'],
      phone: data['phone'],
      website: data['website'],
    );
  }

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
      'kboNumber': businessDetails.kboNumber,
      'legalForm': businessDetails.legalForm,
      'iban': businessDetails.iban,
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
              // Remove unnecessary cast
              final clientData = clientDoc.data();
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
        
        // If there are no todoItems, add some mock data
        if (project.todoItems.isEmpty) {
          // Create mock todo items based on project title to make them unique
          project.todoItems = [
            {
              'id': '${project.id}-task1',
              'title': 'Setup initial ${project.title} framework',
              'completed': true,
            },
            {
              'id': '${project.id}-task2',
              'title': 'Create documentation for ${project.title}',
              'completed': false,
            },
            {
              'id': '${project.id}-task3',
              'title': 'Review ${project.title} progress',
              'completed': false,
            },
          ];
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
      
            // Convert invoices to models and return

      return snapshot.docs
          .map((doc) => InvoiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching invoices: $e');
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  Future<List<InvoiceModel>> getInvoicesForProject(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .where('projectId', isEqualTo: projectId)
        .orderBy('invoiceDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();
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
        .doc(entryId
        )
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

  // Helper for time tracking: get entries for a date range
  Future<List<TimeEntryModel>> getTimeEntriesForDateRange(DateTime start, DateTime end) async {
    return getTimeEntries(startDate: start, endDate: end);
  }
  // Helper for time tracking: mark a project task as in progress (sets completed=false)
  Future<void> markTaskInProgress(String projectId, String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final projectRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId);
    final projectDoc = await projectRef.get();
    if (!projectDoc.exists) return;
    final data = projectDoc.data();
    if (data == null || data['todoItems'] == null) return;
    List todoItems = List.from(data['todoItems']);
    for (var item in todoItems) {
      if (item['id'] == taskId) {
        item['completed'] = false;
      }
    }
    await projectRef.update({'todoItems': todoItems});
  }

  /// Get email settings for the current user
  Future<EmailSettings> getEmailSettings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('email')
        .get();

    if (!doc.exists) {
      throw Exception('Email settings not found');
    }

    return EmailSettings.fromDoc(doc);
  }

  /// Save email settings for the current user
  Future<void> saveEmailSettings(EmailSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('email')
        .set(settings.toMap());
  }
  
  /// Delete email settings for the current user
  Future<void> deleteEmailSettings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('email')
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
  }  // This method is intentionally removed to resolve the duplicate definition error.
  // The functionality is now handled by sendInvoicePdfWithCloudFunction method./// Send invoice PDF by email using HTTP API instead of Cloud Functions
  Future<void> sendInvoicePdfWithCloudFunction({
    required String invoiceId, 
    String? recipientEmail,
    String? logoUrl, 
    String? templateId,
    String? customSubject,
    String? customBody
  }) async {
    try {
      // Get required data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final InvoiceModel invoice = await getInvoice(invoiceId);
      final BusinessDetails businessDetails = await getBusinessDetails();
      
      // If no recipient email provided, get it from the client
      if (recipientEmail == null || recipientEmail.isEmpty) {
        final ClientModel client = await getClient(invoice.clientId);
        recipientEmail = client.email;
        if (recipientEmail.isEmpty) {
          throw Exception('Client heeft geen e-mailadres');
        }
      }

      // Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice: invoice,
        businessDetails: businessDetails,
        logoUrl: logoUrl,
        templateId: templateId,
      );
      
      final pdfBase64 = base64Encode(pdfBytes);
        // Set up email content with invoice details
      final defaultEmailBody = '''
Beste ${invoice.clientName},

Hierbij ontvangt u factuur ${invoice.invoiceNumber}.

Factuurgegevens:
- Factuurnummer: ${invoice.invoiceNumber}
- Factuurdatum: ${DateFormat('dd-MM-yyyy').format(invoice.invoiceDate)}
- Vervaldatum: ${DateFormat('dd-MM-yyyy').format(invoice.dueDate)}
- Bedrag: €${invoice.total.toStringAsFixed(2)}

U kunt de factuur als PDF-bijlage in deze e-mail vinden.

Betaling kunt u overmaken naar:
${businessDetails.iban}
o.v.v. factuurnummer ${invoice.invoiceNumber}

Met vriendelijke groet,
${businessDetails.companyName}
''';

      final emailSubject = customSubject ?? 'Factuur ${invoice.invoiceNumber} van ${businessDetails.companyName}';
      final emailBody = customBody ?? defaultEmailBody;

      // Use HTTP API to send email
      final response = await http.post(
        Uri.parse('$_baseUrl/send-invoice-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}'
        },        body: jsonEncode({
          'to': recipientEmail,
          'subject': emailSubject,
          'body': emailBody,
          'fileName': 'factuur_${invoice.invoiceNumber}.pdf',
          'pdfBase64': pdfBase64,
        }),
      );
      
      if (response.statusCode == 200) {
        print('Email sent successfully');
        
        // Update invoice status to 'sent' and add sendDate
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('invoices')
            .doc(invoiceId)
            .update({
              'status': 'sent',
              'sentAt': FieldValue.serverTimestamp(),
            });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Fout bij verzenden e-mail');
      }
    } catch (e) {
      print('Error sending invoice PDF by email: $e');
      throw Exception('Fout bij verzenden van factuur per e-mail: $e');
    }
  }
}
