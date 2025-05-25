import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

// These imports are needed for the return types of the Firebase service methods
// Adding explicit type annotations to demonstrate usage
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/business_details.dart';

import 'firebase_service.dart';
import 'pdf_service.dart';
import 'peppol_service.dart';

class InvoiceExportService {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfService _pdfService = PdfService();
  final PeppolService _peppolService = PeppolService();
  
  /// Generate and download a PDF invoice (optioneel: logoUrl, templateId)
  Future<void> generateAndDownloadPdf(String invoiceId, {String? logoUrl, String? templateId}) async {
    try {
      final InvoiceModel invoice = await _firebaseService.getInvoice(invoiceId);
      final BusinessDetails businessDetails = await _firebaseService.getBusinessDetails();

      // Genereer PDF met optioneel logo en template
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice: invoice,
        businessDetails: businessDetails,
        logoUrl: logoUrl,
        templateId: templateId,
      );

      _downloadBytes(
        bytes: pdfBytes, 
        fileName: 'factuur_${invoice.invoiceNumber}.pdf',
        mimeType: 'application/pdf',
      );
      return;
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }
  
  /// Genereer en download een lege voorbeeldfactuur als PDF op basis van sjabloon-instellingen
  Future<void> generateAndDownloadPdfPreview({
    String? header,
    String? footer,
    String? color,
    String? logoUrl,
  }) async {
    try {
      // Dummy business details
      final BusinessDetails businessDetails = BusinessDetails(
        companyName: 'Voorbeeld BV',
        kboNumber: '0123.456.789',
        vatNumber: 'BE0123456789',
        address: 'Voorbeeldstraat 1, 1000 Brussel',
        legalForm: 'BV',
        iban: 'BE12 3456 7890 1234',
        defaultVatRate: 21,
        paymentTerms: 30,
        phone: '+32 12 34 56 78',
        website: 'www.voorbeeld.be',
        peppolId: null,
      );
      // Dummy invoice model
      final now = DateTime.now();
      final InvoiceModel invoice = InvoiceModel(
        invoiceNumber: '2025-0001',
        clientId: '',
        clientName: 'Voorbeeldklant',
        invoiceDate: now,
        dueDate: now.add(const Duration(days: 30)),
        lineItems: [
          InvoiceLineItem(description: 'Voorbeeld product/dienst', quantity: 1, unitPrice: 100, amount: 100),
        ],
        subtotal: 100,
        vatRate: 21,
        vatAmount: 21,
        total: 121,
        status: 'draft',
        projectId: null,
        note: '',
        createdAt: now,
        updatedAt: now,
      );
      // Genereer PDF met dummy data en sjabloon
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice: invoice,
        businessDetails: businessDetails,
        logoUrl: logoUrl,
        templateId: null,
      );
      _downloadBytes(
        bytes: pdfBytes,
        fileName: 'voorbeeld_factuur.pdf',
        mimeType: 'application/pdf',
      );
    } catch (e) {
      print('Error generating PDF preview: $e');
      throw Exception('Failed to generate PDF preview: $e');
    }
  }
  
  /// Generate and download a UBL XML file for Peppol
  Future<void> generateAndDownloadUbl(String invoiceId) async {
    try {
      // Get invoice data with explicit type annotation
      final InvoiceModel invoice = await _firebaseService.getInvoice(invoiceId);
      
      // Get business details with explicit type annotation
      final BusinessDetails businessDetails = await _firebaseService.getBusinessDetails();
      
      // Get client data with explicit type annotation
      final ClientModel client = await _firebaseService.getClient(invoice.clientId);
      
      // Check if client has valid Peppol ID or VAT number
      if ((client.peppolId == null || client.peppolId!.isEmpty) && 
          (client.vatNumber == null || client.vatNumber!.isEmpty)) {
        throw Exception('Client must have either a Peppol ID or VAT number to generate UBL');
      }
      
      // Generate UBL XML
      final xmlDoc = _peppolService.generateUblXml(
        invoice: invoice,
        businessDetails: businessDetails,
        client: client,
      );
      
      // Convert to string
      final xmlString = xmlDoc.toXmlString(pretty: true);
      
      // Download the file
      final bytes = Uint8List.fromList(xmlString.codeUnits);
      _downloadBytes(
        bytes: bytes, 
        fileName: 'factuur_${invoice.invoiceNumber}_peppol.xml',
        mimeType: 'application/xml',
      );
      
      return;
    } catch (e) {
      print('Error generating UBL XML: $e');
      throw Exception('Failed to generate UBL XML: $e');
    }
  }
  
  /// Send an invoice via Peppol network
  Future<Map<String, dynamic>> sendViaPeppol(String invoiceId) async {
    try {
      // Get invoice data
      final InvoiceModel invoice = await _firebaseService.getInvoice(invoiceId);
      
      // Get business details
      final BusinessDetails businessDetails = await _firebaseService.getBusinessDetails();
      
      // Check if business has Peppol ID
      if (businessDetails.peppolId == null || businessDetails.peppolId!.isEmpty) {
        return {
          'success': false,
          'message': 'Je bedrijf heeft een Peppol ID nodig om via Peppol te verzenden. Voeg dit toe in je bedrijfsgegevens.',
        };
      }
      
      // Get client data
      final ClientModel client = await _firebaseService.getClient(invoice.clientId);
      
      // Check if client has Peppol ID
      if (client.peppolId == null || client.peppolId!.isEmpty) {
        return {
          'success': false,
          'message': 'De klant heeft een Peppol ID nodig om via Peppol te ontvangen. Voeg dit toe aan de klantgegevens.',
        };
      }
      
      // Validate Peppol IDs
      if (!_peppolService.isValidPeppolId(businessDetails.peppolId!)) {
        return {
          'success': false,
          'message': 'Ongeldig Peppol ID formaat voor je bedrijf. Controleer het formaat (bijv. nl:kvk:12345678)',
        };
      }
      
      if (!_peppolService.isValidPeppolId(client.peppolId!)) {
        return {
          'success': false,
          'message': 'Ongeldig Peppol ID formaat voor de klant. Controleer het formaat (bijv. nl:kvk:12345678)',
        };
      }
      
      // Generate UBL XML - currently unused but would be used in a full implementation
      /*
      final xmlDoc = _peppolService.generateUblXml(
        invoice: invoice,
        businessDetails: businessDetails,
        client: client,
      );
      
      // Send via Peppol...
      */
      
      // For now, we just notify the user that this is a placeholder
      return {
        'success': false,
        'message': 'Peppol verzending is nog niet volledig geïmplementeerd. Om dit te activeren heb je een overeenkomst nodig met een Access Point provider zoals Storecove of Billit.',
        'note': 'De UBL XML is wel correct gegenereerd. Je kunt deze downloaden en handmatig uploaden naar je Access Point provider.',
      };
    } catch (e) {
      print('Error sending via Peppol: $e');
      return {
        'success': false,
        'message': 'Fout bij het verzenden via Peppol: $e',
      };
    }
  }
  
  /// Stuur een PDF-factuur via e-mail naar de client (optioneel: logoUrl, templateId)
  Future<void> sendInvoicePdfByEmail(String invoiceId, {String? logoUrl, String? templateId}) async {
    try {
      final InvoiceModel invoice = await _firebaseService.getInvoice(invoiceId);
      final BusinessDetails businessDetails = await _firebaseService.getBusinessDetails();
      final ClientModel client = await _firebaseService.getClient(invoice.clientId);

      // Genereer PDF met optioneel logo en template
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice: invoice,
        businessDetails: businessDetails,
        logoUrl: logoUrl,
        templateId: templateId,
      );

      final pdfBase64 = base64Encode(pdfBytes);

      final String? clientEmail = client.email;
      if (clientEmail == null || clientEmail.isEmpty) {
        throw Exception('Client heeft geen e-mailadres.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('https://your-backend-url/api/send-invoice-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': clientEmail,
          'subject': 'Factuur ${invoice.invoiceNumber}',
          'body': 'Beste ${client.name},\n\nIn de bijlage vindt u uw factuur.\n\nMet vriendelijke groet,\n${businessDetails.companyName}',
          'pdfBase64': pdfBase64,
          'fileName': 'factuur_${invoice.invoiceNumber}.pdf',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Fout bij verzenden e-mail: ${response.body}');
      }
    } catch (e) {
      print('Error sending invoice PDF by email: $e');
      throw Exception('Failed to send invoice PDF by email: $e');
    }
  }
  
  /// Helper method to download bytes as a file in the browser
  void _downloadBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) {
    // This only works in web environments
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
        
      html.document.body!.children.add(anchor);
      anchor.click();
      html.Url.revokeObjectUrl(url);
      anchor.remove();
    } else {
      // For mobile/desktop, you would use a different approach
      // For example, saving to a file using path_provider package
      throw Exception('Downloading files is only supported in web environment');
    }
  }
}
