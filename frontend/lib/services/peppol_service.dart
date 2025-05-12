import 'package:xml/xml.dart';
import '../models/invoice_model.dart';
import '../models/business_details.dart';
import '../models/client_model.dart';
import 'package:intl/intl.dart';

class PeppolService {
  /// Generates a UBL 2.1 XML document for an invoice (Peppol BIS 3.0 compliant)
  XmlDocument generateUblXml({
    required InvoiceModel invoice,
    required BusinessDetails businessDetails,
    required ClientModel client,
  }) {
    // Date formatters for UBL format (YYYY-MM-DD)
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    // Create the XML document
    final builder = XmlBuilder();
    
    // Add XML declaration
    builder.declaration(encoding: 'UTF-8');
    
    // Root invoice element with namespaces
    builder.element('Invoice', namespaces: {
      'xmlns': 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
      'xmlns:cac': 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
      'xmlns:cbc': 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
    }, nest: () {
      // UBL Version ID
      builder.element('cbc:UBLVersionID', nest: '2.1');
      
      // Customization ID (BIS 3.0)
      builder.element('cbc:CustomizationID', nest: 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0');
      
      // Profile ID (Invoice profile)
      builder.element('cbc:ProfileID', nest: 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
      
      // Invoice ID (invoice number)
      builder.element('cbc:ID', nest: invoice.invoiceNumber);
      
      // Issue date
      builder.element('cbc:IssueDate', nest: dateFormat.format(invoice.invoiceDate));
      
      // Due date
      builder.element('cbc:DueDate', nest: dateFormat.format(invoice.dueDate));
      
      // Invoice type code (380 = Commercial invoice)
      builder.element('cbc:InvoiceTypeCode', nest: '380');
      
      // Document currency code
      builder.element('cbc:DocumentCurrencyCode', nest: 'EUR');
      
      // Accounting cost (optional - project ID if available)
      if (invoice.projectId != null && invoice.projectId!.isNotEmpty) {
        builder.element('cbc:AccountingCost', nest: invoice.projectId);
      }
      
      // Buyer reference (optional)
      // builder.element('cbc:BuyerReference', nest: 'PO-12345');
      
      // Invoice period (optional)
      builder.element('cac:InvoicePeriod', nest: () {
        builder.element('cbc:StartDate', nest: dateFormat.format(invoice.invoiceDate));
        builder.element('cbc:EndDate', nest: dateFormat.format(invoice.dueDate));
      });
      
      // Note (optional)
      if (invoice.note != null && invoice.note!.isNotEmpty) {
        builder.element('cbc:Note', nest: invoice.note);
      }
      
      // Supplier/Account party
      builder.element('cac:AccountingSupplierParty', nest: () {
        builder.element('cac:Party', nest: () {
          // Endpoint ID - the Peppol ID of the supplier
          if (businessDetails.peppolId != null && businessDetails.peppolId!.isNotEmpty) {
            builder.element('cbc:EndpointID', attributes: {
              'schemeID': '0106' // BE:KBO
            }, nest: businessDetails.peppolId);
          } else {
            // If no Peppol ID, use KBO
            builder.element('cbc:EndpointID', attributes: {
              'schemeID': '0106' // BE:KBO
            }, nest: businessDetails.kboNumber);
          }
          
          // Party identification - KBO number
          builder.element('cac:PartyIdentification', nest: () {
            builder.element('cbc:ID', attributes: {
              'schemeID': '0106'  // BE:KBO
            }, nest: businessDetails.kboNumber);
          });
          
          // Party name
          builder.element('cac:PartyName', nest: () {
            builder.element('cbc:Name', nest: businessDetails.companyName);
          });
          
          // Postal address - simplified since we don't have all fields
          builder.element('cac:PostalAddress', nest: () {
            builder.element('cbc:StreetName', nest: businessDetails.address);
            // Assuming BE (Belgium)
            builder.element('cac:Country', nest: () {
              builder.element('cbc:IdentificationCode', nest: 'BE');
            });
          });
          
          // Tax scheme - VAT registration
          builder.element('cac:PartyTaxScheme', nest: () {
            builder.element('cbc:CompanyID', nest: businessDetails.vatNumber);
            builder.element('cac:TaxScheme', nest: () {
              builder.element('cbc:ID', nest: 'VAT');
            });
          });
          
          // Legal entity
          builder.element('cac:PartyLegalEntity', nest: () {
            builder.element('cbc:RegistrationName', nest: businessDetails.companyName);
            builder.element('cbc:CompanyLegalForm', nest: businessDetails.legalForm);
            builder.element('cbc:CompanyID', attributes: {
              'schemeID': '0106'  // BE:KBO
            }, nest: businessDetails.kboNumber);
          });
          
          // Contact information
          builder.element('cac:Contact', nest: () {
            builder.element('cbc:Name', nest: businessDetails.companyName);
            if (businessDetails.phone != null) {
              builder.element('cbc:Telephone', nest: businessDetails.phone);
            }
            if (businessDetails.website != null) {
              builder.element('cbc:ElectronicMail', nest: businessDetails.website);
            }
          });
        });
      });
      
      // Customer/Account party
      builder.element('cac:AccountingCustomerParty', nest: () {
        builder.element('cac:Party', nest: () {          // Endpoint ID
          if (client.peppolId != null && client.peppolId!.isNotEmpty) {
            builder.element('cbc:EndpointID', attributes: {
              'schemeID': '0106' // BE:KBO
            }, nest: client.peppolId);
          } else if (client.vatNumber != null) {
            // If no Peppol ID, try to use VAT number
            builder.element('cbc:EndpointID', attributes: {
              'schemeID': 'VA'
            }, nest: client.vatNumber);
          }
          
          // Party name
          builder.element('cac:PartyName', nest: () {
            builder.element('cbc:Name', nest: client.companyName);
          });
          
          // Postal address - using the available fields
          builder.element('cac:PostalAddress', nest: () {
            builder.element('cbc:StreetName', nest: client.address);
            if (client.city.isNotEmpty) {
              builder.element('cbc:CityName', nest: client.city);
            }
            if (client.postalCode.isNotEmpty) {
              builder.element('cbc:PostalZone', nest: client.postalCode);
            }
            // Assuming BE (Belgium)
            builder.element('cac:Country', nest: () {
              builder.element('cbc:IdentificationCode', nest: 'BE');
            });
          });
          
          // Tax scheme - VAT registration
          if (client.vatNumber != null && client.vatNumber!.isNotEmpty) {
            builder.element('cac:PartyTaxScheme', nest: () {
              builder.element('cbc:CompanyID', nest: client.vatNumber);
              builder.element('cac:TaxScheme', nest: () {
                builder.element('cbc:ID', nest: 'VAT');
              });
            });
          }
            // Contact information
          builder.element('cac:Contact', nest: () {
            builder.element('cbc:Name', nest: client.contactPerson);
            if (client.phone.isNotEmpty) {
              builder.element('cbc:Telephone', nest: client.phone);
            }
            if (client.email.isNotEmpty) {
              builder.element('cbc:ElectronicMail', nest: client.email);
            }
          });
        });
      });
      
      // Payment means
      builder.element('cac:PaymentMeans', nest: () {
        // 30 = Credit transfer
        builder.element('cbc:PaymentMeansCode', nest: '30');
        
        // Payment due date
        builder.element('cbc:PaymentDueDate', nest: dateFormat.format(invoice.dueDate));
        
        // Payment ID (invoice number)
        builder.element('cbc:PaymentID', nest: invoice.invoiceNumber);
          // Payment account info
        builder.element('cac:PayeeFinancialAccount', nest: () {
          builder.element('cbc:ID', nest: businessDetails.iban);
          builder.element('cbc:Name', nest: businessDetails.companyName);
          // No BIC field available in BusinessDetails
        });
      });
        // Payment terms
      builder.element('cac:PaymentTerms', nest: () {
        builder.element('cbc:Note', nest: 'Payment within ${businessDetails.paymentTerms} days');
      });
      
      // Tax total
      builder.element('cac:TaxTotal', nest: () {
        builder.element('cbc:TaxAmount', attributes: {
          'currencyID': 'EUR'
        }, nest: invoice.vatAmount.toStringAsFixed(2));
        
        // Tax subtotal
        builder.element('cac:TaxSubtotal', nest: () {
          builder.element('cbc:TaxableAmount', attributes: {
            'currencyID': 'EUR'
          }, nest: invoice.subtotal.toStringAsFixed(2));
          
          builder.element('cbc:TaxAmount', attributes: {
            'currencyID': 'EUR'
          }, nest: invoice.vatAmount.toStringAsFixed(2));
          
          builder.element('cac:TaxCategory', nest: () {
            builder.element('cbc:ID', nest: 'S'); // Standard rate
            builder.element('cbc:Percent', nest: invoice.vatRate.toStringAsFixed(0));
            builder.element('cac:TaxScheme', nest: () {
              builder.element('cbc:ID', nest: 'VAT');
            });
          });
        });
      });
      
      // Document totals
      builder.element('cac:LegalMonetaryTotal', nest: () {
        builder.element('cbc:LineExtensionAmount', attributes: {
          'currencyID': 'EUR'
        }, nest: invoice.subtotal.toStringAsFixed(2));
        
        builder.element('cbc:TaxExclusiveAmount', attributes: {
          'currencyID': 'EUR'
        }, nest: invoice.subtotal.toStringAsFixed(2));
        
        builder.element('cbc:TaxInclusiveAmount', attributes: {
          'currencyID': 'EUR'
        }, nest: invoice.total.toStringAsFixed(2));
        
        builder.element('cbc:PayableAmount', attributes: {
          'currencyID': 'EUR'
        }, nest: invoice.total.toStringAsFixed(2));
      });
      
      // Invoice lines
      for (var i = 0; i < invoice.lineItems.length; i++) {
        final item = invoice.lineItems[i];
        
        builder.element('cac:InvoiceLine', nest: () {
          builder.element('cbc:ID', nest: (i + 1).toString());
          
          builder.element('cbc:InvoicedQuantity', attributes: {
            'unitCode': 'EA' // Each
          }, nest: item.quantity.toString());
          
          builder.element('cbc:LineExtensionAmount', attributes: {
            'currencyID': 'EUR'
          }, nest: item.amount.toStringAsFixed(2));
          
          // Item description
          builder.element('cac:Item', nest: () {
            builder.element('cbc:Description', nest: item.description);
            builder.element('cbc:Name', nest: item.description);
            
            // Classified tax category
            builder.element('cac:ClassifiedTaxCategory', nest: () {
              builder.element('cbc:ID', nest: 'S'); // Standard rate
              builder.element('cbc:Percent', nest: invoice.vatRate.toStringAsFixed(0));
              builder.element('cac:TaxScheme', nest: () {
                builder.element('cbc:ID', nest: 'VAT');
              });
            });
          });
          
          // Price
          builder.element('cac:Price', nest: () {
            builder.element('cbc:PriceAmount', attributes: {
              'currencyID': 'EUR'
            }, nest: item.unitPrice.toStringAsFixed(2));
          });
        });
      }
    });
    
    // Build and return the XML document
    return builder.buildDocument();
  }
  
  /// Validates if a Peppol ID is in the correct format
  bool isValidPeppolId(String peppolId) {
    // Basic validation - real implementation would be more complex
    // Dutch format for KVK-based Peppol ID: nl:kvk:12345678
    final regex = RegExp(r'^[a-z]{2}:(kvk|vat):\d+$', caseSensitive: false);
    return regex.hasMatch(peppolId);
  }
  
  /// Connects to an Access Point to send the invoice 
  /// This is a placeholder - would require integration with a real Access Point provider
  Future<Map<String, dynamic>> sendToPeppolNetwork({
    required XmlDocument ublDocument,
    required String recipientPeppolId,
    required String senderPeppolId,
    String accessPointUrl = 'https://access.point.provider/api/send',
  }) async {
    // This would be implemented with the specific API of your chosen Access Point provider
    // For example, Storecove, Billit, etc.
    
    // In a real implementation, you would:
    // 1. Format the request according to the provider's API
    // 2. Send the UBL document to the Access Point
    // 3. Handle the response, errors, etc.
    
    // This is just a placeholder
    return {
      'success': false,
      'message': 'Peppol sending functionality requires integration with an Access Point provider',
      'recipientId': recipientPeppolId,
      'senderId': senderPeppolId,
      'documentId': ublDocument.rootElement.findElements('cbc:ID').first.text,
    };
  }
  
  /// Check if a VAT number is valid using VIES API
  /// This is a placeholder - would require integration with the VIES validation service
  Future<bool> validateVatNumber(String vatNumber) async {
    // In a real implementation, you would call the VIES API
    // or use a service like https://ec.europa.eu/taxation_customs/vies/
    
    // This is just a placeholder
    return true;
  }
}
