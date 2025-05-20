import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'card_3d_effect.dart';

class InvoicePreview extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  
  const InvoicePreview({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card3DEffect(
      depth: 0.008,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                Colors.black.r.toInt(),
                Colors.black.g.toInt(),
                Colors.black.b.toInt(),
                0.1,
              ),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Color.fromRGBO(
                primaryColor.r.toInt(),
                primaryColor.g.toInt(),
                primaryColor.b.toInt(),
                0.08,
              ),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Invoice Header
              _buildInvoiceHeader(),
              
              // Invoice Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceInfo(),
                    const SizedBox(height: 32),
                    _buildInvoiceTable(),
                    const SizedBox(height: 32),
                    _buildInvoiceSummary(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 200.ms).scale(
      begin: const Offset(0.97, 0.97),
      end: const Offset(1, 1),
      duration: 800.ms,
      curve: Curves.easeOutQuint,
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              Colors.black.r.toInt(),
              Colors.black.g.toInt(),
              Colors.black.b.toInt(),
              0.05,
            ),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: primaryColor,
                size: 28,
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVOICE',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    '#INV-2024-0042',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.download, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Download PDF',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Company, Inc.',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '123 Business Avenue\nNew York, NY 10001\nUnited States',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Acme Corporation',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '456 Corporate Drive\nSan Francisco, CA 94107\nUnited States',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Details',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Invoice Number:', '#INV-2024-0042'),
              const SizedBox(height: 4),
              _buildDetailRow('Date Issued:', 'May 15, 2024'),
              const SizedBox(height: 4),
              _buildDetailRow('Due Date:', 'June 14, 2024'),
              const SizedBox(height: 4),
              _buildDetailRow('Status:', 'Sent'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Hours',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Rate',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        
        // Items
        _buildInvoiceItem(
          description: 'Website Redesign',
          hours: '42.5',
          rate: '\$85.00',
          amount: '\$3,612.50',
        ),
        _buildInvoiceItem(
          description: 'UI/UX Consultation',
          hours: '12.0',
          rate: '\$95.00',
          amount: '\$1,140.00',
        ),
        _buildInvoiceItem(
          description: 'Content Creation',
          hours: '8.5',
          rate: '\$75.00',
          amount: '\$637.50',
        ),
      ],
    );
  }

  Widget _buildInvoiceItem({
    required String description,
    required String hours,
    required String rate,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hours,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Row(
      children: [
        const Spacer(flex: 5),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSummaryRow('Subtotal:', '\$5,390.00'),
              const SizedBox(height: 8),
              _buildSummaryRow('Tax (10%):', '\$539.00'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 2),
                  ),
                ),
                child: _buildSummaryRow(
                  'Total Due:',
                  '\$5,929.00',
                  isTotal: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}
