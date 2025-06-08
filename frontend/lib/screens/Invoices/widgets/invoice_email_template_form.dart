import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceEmailTemplateForm extends StatefulWidget {
  const InvoiceEmailTemplateForm({super.key});

  @override
  State<InvoiceEmailTemplateForm> createState() => _InvoiceEmailTemplateFormState();
}

class _InvoiceEmailTemplateFormState extends State<InvoiceEmailTemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmailTemplate();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadEmailTemplate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('email')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _subjectController.text = data['defaultSubjectTemplate'] ?? _getDefaultSubjectTemplate();
        _bodyController.text = data['defaultBodyTemplate'] ?? _getDefaultBodyTemplate();
      } else {
        _subjectController.text = _getDefaultSubjectTemplate();
        _bodyController.text = _getDefaultBodyTemplate();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  String _getDefaultSubjectTemplate() {
    return 'Factuur {invoiceNumber} van {companyName}';
  }

  String _getDefaultBodyTemplate() {
    return '''Beste {clientName},

In de bijlage vindt u factuur {invoiceNumber}.

Factuurgegevens:
- Factuurnummer: {invoiceNumber}
- Factuurdatum: {invoiceDate}
- Vervaldatum: {dueDate}
- Subtotaal: €{subtotal}
- BTW ({vatRate}%): €{vatAmount}
- Totaalbedrag: €{total}

{note}

U kunt het bedrag overmaken naar:
IBAN: {iban}
Ten name van: {companyName}
Onder vermelding van: {invoiceNumber}

Met vriendelijke groet,
{companyName}''';
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('email')
          .set({
            'defaultSubjectTemplate': _subjectController.text,
            'defaultBodyTemplate': _bodyController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mailsjabloon opgeslagen')),
      );

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, String> _getPreviewData() {
    return {
      'invoiceNumber': '2024-001',
      'companyName': 'Voorbeeld BV',
      'clientName': 'John Doe',
      'invoiceDate': '15-01-2024',
      'dueDate': '14-02-2024',
      'subtotal': '1000,00',
      'vatRate': '21',
      'vatAmount': '210,00',
      'total': '1210,00',
      'note': 'Bedankt voor uw vertrouwen in onze diensten.',
      'iban': 'NL91 INGB 0123 4567 89',
    };
  }

  void _showPreview() {
    final previewData = _getPreviewData();
    var subject = _subjectController.text;
    var body = _bodyController.text;

    // Replace placeholders with preview data
    previewData.forEach((key, value) {
      subject = subject.replaceAll('{$key}', value);
      body = body.replaceAll('{$key}', value);
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voorbeeld e-mail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onderwerp: $subject',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 24),
                    Text(body),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Sluiten'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.email_outlined),
                  SizedBox(width: 8),
                  Text(
                    'E-mailsjabloon voor facturen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description and placeholders
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700]),
                  children: const [
                    TextSpan(
                      text: 'Pas de e-mail aan die met facturen wordt verzonden. ',
                    ),
                    TextSpan(
                      text: 'Verplichte placeholders',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: ': {clientName}, {invoiceNumber}, {total}. Beschikbare placeholders:',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPlaceholder('invoiceNumber'),
                  _buildPlaceholder('companyName'),
                  _buildPlaceholder('clientName'),
                  _buildPlaceholder('invoiceDate'),
                  _buildPlaceholder('dueDate'),
                  _buildPlaceholder('subtotal'),
                  _buildPlaceholder('vatRate'),
                  _buildPlaceholder('vatAmount'),
                  _buildPlaceholder('total'),
                  _buildPlaceholder('note'),
                  _buildPlaceholder('iban'),
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(244, 67, 54, 0.1), // Colors.red with 0.1 opacity
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Subject field
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Onderwerp',
                  border: OutlineInputBorder(),
                  hintText: 'Bijv: Factuur {invoiceNumber} van {companyName}',
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Het onderwerp van de e-mail is verplicht';
                  }
                  if (!value!.contains('{invoiceNumber}')) {
                    return 'Het onderwerp moet tenminste de placeholder {invoiceNumber} bevatten';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Body field
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Bericht',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText: 'Gebruik Enter voor een nieuwe regel.',
                  helperMaxLines: 2,
                ),
                maxLines: 12,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'De inhoud van de e-mail is verplicht';
                  }
                  
                  final requiredPlaceholders = [
                    '{clientName}',
                    '{invoiceNumber}',
                    '{total}',
                  ];
                  
                  for (final placeholder in requiredPlaceholders) {
                    if (!value!.contains(placeholder)) {
                      return 'De e-mail moet de placeholder $placeholder bevatten';
                    }
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Standaardsjabloon herstellen'),
                          content: const Text(
                            'Weet u zeker dat u de aanpassingen wilt vervangen door het standaardsjabloon?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Annuleren'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _loadEmailTemplate();
                              },
                              child: const Text('Herstellen'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Standaard herstellen'),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showPreview,
                        icon: const Icon(Icons.remove_red_eye),
                        label: const Text('Voorbeeld'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF28A745),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton.icon(
                          onPressed: _saveTemplate,
                          icon: const Icon(Icons.save),
                          label: const Text('Sjabloon opslaan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B5394),
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Chip(
      label: Text('{$name}'),
      backgroundColor: Colors.grey[200],
    );
  }
}
