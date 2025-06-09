import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';
import '../models/business_details.dart';

class PdfService {
  /// Generates a PDF document for an invoice
  Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required BusinessDetails businessDetails,
    String? logoUrl,
    String? templateId,
  }) async {
    // Create a PDF document
    final pdf = pw.Document();
    
    // Load fonts
    final robotoData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final roboto = pw.Font.ttf(robotoData);
    
    // Create font fallback to ensure all symbols are rendered
    final fontFallback = await Future.wait([
      rootBundle.load("assets/fonts/Roboto-Regular.ttf").then((data) => pw.Font.ttf(data)),
      // Add additional fonts here if needed for specific symbols
    ]);

    // Define styles with font fallback
    final baseStyle = pw.TextStyle(
      font: roboto,
      fontSize: 12,
      fontFallback: fontFallback,
    );

    final headerStyle = baseStyle.copyWith(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );

    final subheaderStyle = baseStyle.copyWith(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    final bodyStyle = baseStyle;

    final smallStyle = baseStyle.copyWith(
      fontSize: 10,
      color: PdfColors.grey700,
    );

    // Use Euro symbol directly in formatters
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat.currency(
      locale: 'nl_NL',
      symbol: '€',
      decimalDigits: 2,
    );

    pw.ImageProvider? logoImage;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // Selecteer sjabloon op basis van templateId
    switch (templateId) {
      case 'modern':
        // Bouw een modern sjabloon
        pdf.addPage(
          pw.MultiPage(
            build: (context) => [
              if (logoImage != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logoImage, height: 60),
                ),
              pw.Text('Factuur (Modern Template)', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              // ...rest van de factuur...
            ],
          ),
        );
        break;
      case 'classic':
        // Bouw een klassiek sjabloon
        pdf.addPage(
          pw.MultiPage(
            build: (context) => [
              if (logoImage != null)
                pw.Center(child: pw.Image(logoImage, height: 80)),
              pw.Text('Factuur (Classic Template)', style: pw.TextStyle(fontSize: 20)),
              // ...rest van de factuur...
            ],
          ),
        );
        break;
      default:
        // Standaard sjabloon
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => [
              if (logoImage != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logoImage, height: 60),
                ),
              // Header with logo and business info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Business info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessDetails.companyName, style: headerStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(businessDetails.address, style: bodyStyle),
                      pw.Text('BTW: ${businessDetails.vatNumber}', style: bodyStyle),
                      pw.Text('KBO: ${businessDetails.kboNumber}', style: bodyStyle),
                      if (businessDetails.website != null)
                        pw.Text('Website: ${businessDetails.website}', style: bodyStyle),
                    ],
                  ),
                  // Invoice info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FACTUUR', style: headerStyle),
                      pw.SizedBox(height: 8),
                      pw.Text('Factuurnummer: ${invoice.invoiceNumber}', style: bodyStyle),
                      pw.Text('Datum: ${dateFormat.format(invoice.invoiceDate)}', style: bodyStyle),
                      pw.Text('Vervaldatum: ${dateFormat.format(invoice.dueDate)}', style: bodyStyle),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Client info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Factuur voor:', style: subheaderStyle),
                    pw.SizedBox(height: 8),
                    pw.Text(invoice.clientName, style: bodyStyle),
                    // Hier zou je meer klantgegevens kunnen toevoegen
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Invoice items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Description
                  1: const pw.FlexColumnWidth(1), // Quantity
                  2: const pw.FlexColumnWidth(1), // Unit price
                  3: const pw.FlexColumnWidth(1.5), // Amount
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Omschrijving', style: subheaderStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Aantal', style: subheaderStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Prijs', style: subheaderStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Bedrag', style: subheaderStyle, textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),

                  // Table rows for each item
                  ...invoice.lineItems.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.description, style: bodyStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item.quantity.toString(),
                            style: bodyStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            moneyFormat.format(item.unitPrice),
                            style: bodyStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            moneyFormat.format(item.amount),
                            style: bodyStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 150,
                          child: pw.Text('Subtotaal:', style: bodyStyle),
                        ),
                        pw.Container(
                          width: 100,
                          child: pw.Text(
                            moneyFormat.format(invoice.subtotal),
                            style: bodyStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 150,
                          child: pw.Text('BTW (${invoice.vatRate.toStringAsFixed(0)}%):', style: bodyStyle),
                        ),
                        pw.Container(
                          width: 100,
                          child: pw.Text(
                            moneyFormat.format(invoice.vatAmount),
                            style: bodyStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text('Totaal:', style: subheaderStyle),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              moneyFormat.format(invoice.total),
                              style: subheaderStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 40),

              // Note / Terms
              if (invoice.note != null && invoice.note!.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Opmerkingen:', style: subheaderStyle),
                    pw.SizedBox(height: 8),
                    pw.Text(invoice.note!, style: bodyStyle),
                  ],
                ),

              pw.SizedBox(height: 20),

              // Payment details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Betalingsgegevens:', style: subheaderStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('IBAN: ${businessDetails.iban}', style: bodyStyle),
                  pw.Text('Juridische vorm: ${businessDetails.legalForm}', style: bodyStyle),
                  if (businessDetails.phone != null)
                    pw.Text('Telefoon: ${businessDetails.phone}', style: bodyStyle),
                  pw.SizedBox(height: 4),
                  pw.Text('Betaaltermijn: ${invoice.dueDate.difference(invoice.invoiceDate).inDays} dagen', style: bodyStyle),
                ],
              ),

              // Footer
              pw.SizedBox(height: 40),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Bedankt voor uw vertrouwen in ${businessDetails.companyName}',
                  style: smallStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
            footer: (context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'Pagina ${context.pageNumber} van ${context.pagesCount}',
                  style: smallStyle,
                ),
              );
            },
          ),
        );
    }

    // Return the PDF document as a Uint8List
    return pdf.save();
  }
}
