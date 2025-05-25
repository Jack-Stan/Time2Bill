import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/invoice_export_service.dart';

class EditInvoiceTemplatePage extends StatefulWidget {
  const EditInvoiceTemplatePage({Key? key}) : super(key: key);

  @override
  State<EditInvoiceTemplatePage> createState() => _EditInvoiceTemplatePageState();
}

class _EditInvoiceTemplatePageState extends State<EditInvoiceTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Niet ingelogd');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('invoice_template')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _headerController.text = data['header'] ?? '';
        _footerController.text = data['footer'] ?? '';
        _colorController.text = data['color'] ?? '';
        _logoUrlController.text = data['logoUrl'] ?? '';
      }
    } catch (e) {
      setState(() { _errorMessage = 'Fout bij laden: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Niet ingelogd');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('invoice_template')
          .set({
        'header': _headerController.text,
        'footer': _footerController.text,
        'color': _colorController.text,
        'logoUrl': _logoUrlController.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sjabloon opgeslagen!')),
      );
    } catch (e) {
      setState(() { _errorMessage = 'Fout bij opslaan: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factuursjabloon bewerken'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulier links
                  Expanded(
                    flex: 1,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (_errorMessage != null) ...[
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _headerController,
                            decoration: const InputDecoration(
                              labelText: 'Header (bovenaan factuur)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _footerController,
                            decoration: const InputDecoration(
                              labelText: 'Footer (onderaan factuur)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Primaire kleur (hex, bv. #0B5394)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _logoUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Logo URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _saveTemplate,
                            icon: const Icon(Icons.save),
                            label: const Text('Opslaan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Preview rechts
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _buildStyledTemplatePreview(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStyledTemplatePreview() {
    final color = _colorController.text.isNotEmpty ? _colorController.text : '#0B5394';
    final header = _headerController.text;
    final footer = _footerController.text;
    final logoUrl = _logoUrlController.text;
    Color? parsedColor;
    try {
      parsedColor = Color(int.parse(color.replaceFirst('#', '0xff')));
    } catch (_) {
      parsedColor = const Color(0xFF0B5394);
    }
    return Center(
      child: Container(
        width: 540,
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: parsedColor.withOpacity(0.25), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
              decoration: BoxDecoration(
                color: parsedColor.withOpacity(0.13),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (logoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(logoUrl, height: 54, errorBuilder: (c, e, s) => const SizedBox()),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      header.isNotEmpty ? header : 'Voorbeeld BV',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: parsedColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: parsedColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('FACTUUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            // Client & Invoice Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Factuur voor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Voorbeeldklant', style: TextStyle(fontSize: 15)),
                        Text('Voorbeeldstraat 2, 1000 Brussel', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Factuurnummer: 2025-0001', style: TextStyle(fontSize: 15)),
                        Text('Datum: 21/05/2025', style: const TextStyle(fontSize: 15)),
                        const Text('Vervaldatum: 20/06/2025', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade200),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: parsedColor.withOpacity(0.08)),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Omschrijving', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Aantal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Prijs', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Bedrag', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Voorbeeld product/dienst'),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('1', textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('€ 100,00', textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('€ 100,00', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Totals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text('Subtotaal:', style: TextStyle(fontSize: 15)),
                      SizedBox(width: 12),
                      Text('€ 100,00', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text('BTW (21%):', style: TextStyle(fontSize: 15)),
                      SizedBox(width: 12),
                      Text('€ 21,00', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Totaal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: parsedColor)),
                      const SizedBox(width: 12),
                      Text('€ 121,00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: parsedColor)),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
              decoration: BoxDecoration(
                color: parsedColor.withOpacity(0.10),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Text(
                footer.isNotEmpty ? footer : 'Bedankt voor uw vertrouwen in Voorbeeld BV',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _colorController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }
}
