import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/email_settings.dart';
import '../models/business_details.dart';
import 'firebase_service.dart';

class AutoInvoiceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  
  /// Check for invoices that need to be automatically sent based on criteria
  Future<void> processAutomaticSending() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Check if auto-sending is enabled in settings
      final emailSettingsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('email')
          .get();
          
      if (!emailSettingsDoc.exists) {
        print('Email settings not configured, skipping auto-send');
        return;
      }
      
      final EmailSettings emailSettings = EmailSettings.fromDoc(emailSettingsDoc);
      
      if (!emailSettings.autoSendEnabled) {
        print('Auto-send is disabled in settings');
        return;
      }
      
      // Get business details for sending emails
      final BusinessDetails businessDetails = await _firebaseService.getBusinessDetails();
      
      // Process unsent draft invoices
      await _processUnsentInvoices(user.uid, emailSettings, businessDetails);
      
      // Process overdue invoices that need reminders
      await _processOverdueInvoices(user.uid, emailSettings, businessDetails);
      
      // Process recurring invoices that need to be generated
      await _processRecurringInvoices(user.uid, emailSettings, businessDetails);
      
    } catch (e) {
      print('Error in automatic invoice processing: $e');
    }
  }
  
  /// Process draft invoices that need to be sent
  Future<void> _processUnsentInvoices(
    String userId, 
    EmailSettings emailSettings,
    BusinessDetails businessDetails
  ) async {
    try {
      // Get all draft invoices
      final unsent = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .where('status', isEqualTo: 'draft')
          .where('autoSend', isEqualTo: true)
          .get();
          
      for (final doc in unsent.docs) {
        try {
          final invoice = InvoiceModel.fromFirestore(doc);
          
          // Send the invoice via email
          await _sendInvoiceEmail(
            userId: userId,
            invoice: invoice,
            emailSettings: emailSettings,
            businessDetails: businessDetails,
          );
          
          // Update invoice status to 'sent'
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('invoices')
              .doc(invoice.id)
              .update({
                'status': 'sent',
                'sentAt': FieldValue.serverTimestamp(),
              });
              
          print('Auto-sent invoice ${invoice.invoiceNumber}');
        } catch (e) {
          print('Error auto-sending invoice ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error processing unsent invoices: $e');
    }
  }
  
  /// Process overdue invoices that need reminders
  Future<void> _processOverdueInvoices(
    String userId, 
    EmailSettings emailSettings,
    BusinessDetails businessDetails
  ) async {
    try {
      // Get current date
      final now = DateTime.now();
      
      // Get invoices that are due and sent but not paid
      final overdueInvoices = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .where('status', isEqualTo: 'sent')
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();
          
      for (final doc in overdueInvoices.docs) {
        try {
          final invoice = InvoiceModel.fromFirestore(doc);
          final data = doc.data();
          
          // Check if reminder has been sent recently (don't spam clients)
          final lastReminderDate = data['lastReminderDate'] != null 
              ? (data['lastReminderDate'] as Timestamp).toDate() 
              : null;
              
          if (lastReminderDate == null || 
              now.difference(lastReminderDate).inDays >= 7) { // Send reminders weekly
            
            // Send reminder email
            await _sendReminderEmail(
              userId: userId,
              invoice: invoice,
              emailSettings: emailSettings,
              businessDetails: businessDetails,
            );
            
            // Update invoice with reminder date and overdue status
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('invoices')
                .doc(invoice.id)
                .update({
                  'status': 'overdue',
                  'lastReminderDate': FieldValue.serverTimestamp(),
                });
                
            print('Sent reminder for overdue invoice ${invoice.invoiceNumber}');
          }
        } catch (e) {
          print('Error processing overdue invoice ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error processing overdue invoices: $e');
    }
  }
  
  /// Process recurring invoices that need to be generated
  Future<void> _processRecurringInvoices(
    String userId, 
    EmailSettings emailSettings,
    BusinessDetails businessDetails
  ) async {
    try {
      // Get current date
      final now = DateTime.now();
      
      // Get active recurring invoices ready to be generated
      final recurringInvoices = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recurringInvoices')
          .where('active', isEqualTo: true)
          .where('nextGenerationDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();
          
      for (final doc in recurringInvoices.docs) {
        try {
          final data = doc.data();
          
          // Generate a new invoice from the recurring template
          final newInvoiceId = await _generateInvoiceFromRecurring(userId, doc.id, data);
          
          if (newInvoiceId != null && data['autoSend'] == true) {
            // Fetch the newly created invoice
            final newInvoiceDoc = await _firestore
                .collection('users')
                .doc(userId)
                .collection('invoices')
                .doc(newInvoiceId)
                .get();
                
            if (newInvoiceDoc.exists) {
              final invoice = InvoiceModel.fromFirestore(newInvoiceDoc);
              
              // Send the invoice via email
              await _sendInvoiceEmail(
                userId: userId,
                invoice: invoice,
                emailSettings: emailSettings,
                businessDetails: businessDetails,
              );
              
              // Update invoice status to 'sent'
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('invoices')
                  .doc(invoice.id)
                  .update({
                    'status': 'sent',
                    'sentAt': FieldValue.serverTimestamp(),
                  });
                  
              print('Auto-sent recurring invoice ${invoice.invoiceNumber}');
            }
          }
          
          // Update next generation date based on frequency
          await _updateNextGenerationDate(userId, doc.id, data);
          
        } catch (e) {
          print('Error processing recurring invoice ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error processing recurring invoices: $e');
    }
  }
  
  /// Generate a new invoice from a recurring invoice template
  Future<String?> _generateInvoiceFromRecurring(
    String userId, 
    String recurringId,
    Map<String, dynamic> recurringData
  ) async {
    try {
      // Generate invoice number
      final currentYear = DateTime.now().year;
      final invoiceNumberQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .where('invoiceNumber', isGreaterThanOrEqualTo: '$currentYear-')
          .where('invoiceNumber', isLessThan: '${currentYear+1}-')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();
          
      String invoiceNumber;
      if (invoiceNumberQuery.docs.isNotEmpty) {
        final lastInvoiceNumber = invoiceNumberQuery.docs.first['invoiceNumber'] as String;
        final parts = lastInvoiceNumber.split('-');
        if (parts.length == 2) {
          final lastNumber = int.tryParse(parts[1]) ?? 0;
          invoiceNumber = '$currentYear-${(lastNumber + 1).toString().padLeft(3, '0')}';
        } else {
          invoiceNumber = '$currentYear-001';
        }
      } else {
        invoiceNumber = '$currentYear-001';
      }
      
      // Set invoice dates
      final now = DateTime.now();
      final dueDate = now.add(Duration(days: recurringData['paymentTermDays'] ?? 30));            // Create new invoice document
      final newInvoiceRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .add({
            'invoiceNumber': invoiceNumber,
            'clientId': recurringData['clientId'],
            'clientName': recurringData['clientName'],
            'invoiceDate': Timestamp.fromDate(now),
            'dueDate': Timestamp.fromDate(dueDate),
            'subtotal': recurringData['amount'],
            'vatRate': recurringData['vatRate'] ?? 21,
            'vatAmount': (recurringData['amount'] as num) * ((recurringData['vatRate'] as num? ?? 21) / 100),
            'total': (recurringData['amount'] as num) * (1 + ((recurringData['vatRate'] as num? ?? 21) / 100)),
            'status': 'draft',
            'note': recurringData['description'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lineItems': [
              {
                'description': recurringData['description'] ?? 'Recurring invoice',
                'quantity': 1,
                'unitPrice': recurringData['amount'],
                'amount': recurringData['amount'],
              }
            ],
            'generatedFromRecurring': true,
            'recurringInvoiceId': recurringId,
            'autoSend': recurringData['autoSend'] ?? false, // Add autoSend flag from recurring invoice
          });
          
      // Update the recurring invoice with last generated info
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recurringInvoices')
          .doc(recurringId)
          .update({
            'lastGeneratedDate': FieldValue.serverTimestamp(),
            'lastGeneratedInvoiceId': newInvoiceRef.id,
          });
          
      return newInvoiceRef.id;
    } catch (e) {
      print('Error generating invoice from recurring template: $e');
      return null;
    }
  }
  
  /// Update the next generation date for a recurring invoice
  Future<void> _updateNextGenerationDate(
    String userId, 
    String recurringId, 
    Map<String, dynamic> data
  ) async {
    try {
      final frequency = data['frequency'] as String? ?? 'monthly';
      final nextDate = (data['nextGenerationDate'] as Timestamp).toDate();
      
      DateTime newNextDate;
      
      switch (frequency) {
        case 'weekly':
          newNextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'biweekly':
          newNextDate = nextDate.add(const Duration(days: 14));
          break;
        case 'monthly':
          // Add 1 month (approximated as 30 days)
          newNextDate = DateTime(
            nextDate.year, 
            nextDate.month + 1, 
            nextDate.day,
          );
          break;
        case 'quarterly':
          // Add 3 months
          newNextDate = DateTime(
            nextDate.year, 
            nextDate.month + 3, 
            nextDate.day,
          );
          break;
        case 'biannually':
          // Add 6 months
          newNextDate = DateTime(
            nextDate.year, 
            nextDate.month + 6, 
            nextDate.day,
          );
          break;
        case 'annually':
          // Add 1 year
          newNextDate = DateTime(
            nextDate.year + 1, 
            nextDate.month, 
            nextDate.day,
          );
          break;
        default:
          newNextDate = nextDate.add(const Duration(days: 30));
      }
      
      // Check if we've passed the end date (if set)
      final endDate = data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null;
          
      if (endDate != null && newNextDate.isAfter(endDate)) {
        // We've reached the end date, deactivate the recurring invoice
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recurringInvoices')
            .doc(recurringId)
            .update({
              'active': false,
              'deactivatedAt': FieldValue.serverTimestamp(),
              'deactivationReason': 'End date reached',
            });
      } else {
        // Update next generation date
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recurringInvoices')
            .doc(recurringId)
            .update({
              'nextGenerationDate': Timestamp.fromDate(newNextDate),
            });
      }
    } catch (e) {
      print('Error updating next generation date: $e');
    }
  }
  
  /// Send invoice email
  Future<void> _sendInvoiceEmail({
    required String userId,
    required InvoiceModel invoice,
    required EmailSettings emailSettings,
    required BusinessDetails businessDetails,
  }) async {
    try {
      // Get client email
      final clientDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('clients')
          .doc(invoice.clientId)
          .get();
          
      if (!clientDoc.exists) {
        throw Exception('Client not found');
      }
      
      final clientEmail = clientDoc.data()?['email'] as String?;
      if (clientEmail == null || clientEmail.isEmpty) {
        throw Exception('Client has no email address');
      }
      
      // Process email templates
      final dateFormat = DateFormat('dd-MM-yyyy');
      final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
      
      final subject = _processTemplate(
        emailSettings.defaultSubjectTemplate,
        {
          'invoiceNumber': invoice.invoiceNumber,
          'companyName': businessDetails.companyName,
          'clientName': invoice.clientName,
          'invoiceDate': dateFormat.format(invoice.invoiceDate),
          'dueDate': dateFormat.format(invoice.dueDate),
          'total': currencyFormat.format(invoice.total),
          'iban': businessDetails.iban,
        },
      );
      
      final body = _processTemplate(
        emailSettings.defaultBodyTemplate,
        {
          'invoiceNumber': invoice.invoiceNumber,
          'companyName': businessDetails.companyName,
          'clientName': invoice.clientName,
          'invoiceDate': dateFormat.format(invoice.invoiceDate),
          'dueDate': dateFormat.format(invoice.dueDate),
          'total': currencyFormat.format(invoice.total),
          'iban': businessDetails.iban,
        },
      );
        // Send the email using the Firebase service
      await _firebaseService.sendInvoicePdfWithCloudFunction(
        invoiceId: invoice.id,
        recipientEmail: clientEmail,
        customSubject: subject,
        customBody: body,
      );
      
    } catch (e) {
      print('Error sending invoice email: $e');
      throw e;
    }
  }
  
  /// Send reminder email for overdue invoice
  Future<void> _sendReminderEmail({
    required String userId,
    required InvoiceModel invoice,
    required EmailSettings emailSettings,
    required BusinessDetails businessDetails,
  }) async {
    try {
      // Get client email
      final clientDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('clients')
          .doc(invoice.clientId)
          .get();
          
      if (!clientDoc.exists) {
        throw Exception('Client not found');
      }
      
      final clientEmail = clientDoc.data()?['email'] as String?;
      if (clientEmail == null || clientEmail.isEmpty) {
        throw Exception('Client has no email address');
      }
      
      // Process reminder templates
      final dateFormat = DateFormat('dd-MM-yyyy');
      final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
      
      final subject = 'Herinnering: Factuur ${invoice.invoiceNumber} is vervallen';
      
      final body = '''Beste ${invoice.clientName},

Dit is een herinnering dat factuur ${invoice.invoiceNumber} vervallen is.

Factuurgegevens:
- Factuurnummer: ${invoice.invoiceNumber}
- Factuurdatum: ${dateFormat.format(invoice.invoiceDate)}
- Vervaldatum: ${dateFormat.format(invoice.dueDate)}
- Bedrag: ${currencyFormat.format(invoice.total)}

Indien u de betaling reeds heeft uitgevoerd, kunt u deze herinnering als niet verzonden beschouwen.

Betaling kunt u overmaken naar:
${businessDetails.iban}
o.v.v. factuurnummer ${invoice.invoiceNumber}

Met vriendelijke groet,
${businessDetails.companyName}''';
        // Send the reminder email with the invoice attached again
      await _firebaseService.sendInvoicePdfWithCloudFunction(
        invoiceId: invoice.id,
        recipientEmail: clientEmail,
        customSubject: subject,
        customBody: body,
      );
      
    } catch (e) {
      print('Error sending reminder email: $e');
      throw e;
    }
  }
  
  /// Process a template by replacing placeholders with actual values
  String _processTemplate(String template, Map<String, String> values) {
    String result = template;
    values.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
