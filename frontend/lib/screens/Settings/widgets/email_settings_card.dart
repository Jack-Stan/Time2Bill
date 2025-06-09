import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/email_settings.dart';

class EmailSettingsCard extends StatefulWidget {
  final EmailSettings? settings;
  final Function(Map<String, dynamic>) onSave;

  const EmailSettingsCard({
    super.key,
    this.settings,
    required this.onSave,
  });

  @override
  State<EmailSettingsCard> createState() => _EmailSettingsCardState();
}

class _EmailSettingsCardState extends State<EmailSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _hostController = TextEditingController(text: 'smtp.gmail.com');
  final _portController = TextEditingController(text: '587');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'aecx rqvr egvr swhk');
  final _subjectTemplateController = TextEditingController();
  final _bodyTemplateController = TextEditingController();
  bool _useSSL = true;
  bool _autoSendEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.settings != null) {
      _hostController.text = widget.settings!.smtpHost;
      _portController.text = widget.settings!.smtpPort.toString();
      _emailController.text = widget.settings!.smtpEmail;
      _passwordController.text = widget.settings!.smtpPassword;
      _useSSL = widget.settings!.smtpSecure;
      _autoSendEnabled = widget.settings!.autoSendEnabled;
      _subjectTemplateController.text = widget.settings!.defaultSubjectTemplate;
      _bodyTemplateController.text = widget.settings!.defaultBodyTemplate;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _subjectTemplateController.dispose();
    _bodyTemplateController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() != true) return;

    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });

    final settings = {
      'smtpHost': _hostController.text,
      'smtpPort': int.parse(_portController.text),
      'smtpSecure': _useSSL,
      'smtpEmail': _emailController.text,
      'smtpPassword': _passwordController.text,
      'autoSendEnabled': _autoSendEnabled,
      'defaultSubjectTemplate': _subjectTemplateController.text,
      'defaultBodyTemplate': _bodyTemplateController.text,
    };

    widget.onSave(settings);
  }

  Future<void> _testConnection() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = {
        'smtpHost': _hostController.text,
        'smtpPort': int.parse(_portController.text),
        'smtpSecure': _useSSL,
        'smtpEmail': _emailController.text,
        'smtpPassword': _passwordController.text,
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/test-smtp-connection'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        },
        body: jsonEncode(settings),
      );

      if (response.statusCode != 200) {
        throw Exception('Connection failed: ${response.body}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection test successful!')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              Row(
                children: [
                  const Icon(Icons.email, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'E-mailinstellingen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Help Section
              ExpansionTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('E-mail Configuratie Handleiding'),
                subtitle: const Text('Stapsgewijze instructies voor het instellen van je e-mail'),
                initiallyExpanded: widget.settings == null,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Belangrijke beveiligingswaarschuwing
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 236, 179, 1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color.fromRGBO(255, 224, 130, 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color.fromRGBO(245, 124, 0, 1)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Belangrijke Beveiligingsopmerking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(230, 81, 0, 1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gebruik nooit je hoofdwachtwoord van je e-mail. Maak altijd een specifiek app-wachtwoord aan voor de veiligheid.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Gmail Sectie
                        Text(
                          'Gmail Configuratie',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gmail instellen:\n'
                          '1. Open je Google Account instellingen\n'
                          '2. Ga naar Beveiliging → 2-stapsverificatie\n'
                          '3. Scroll naar "App-wachtwoorden"\n'
                          '4. Maak een nieuw app-wachtwoord aan voor "Mail"\n'
                          '5. Gebruik deze instellingen:\n'
                          '   • SMTP Server: smtp.gmail.com\n'
                          '   • Poort: 587\n'
                          '   • E-mail: je Gmail adres\n'
                          '   • Wachtwoord: het gegenereerde app-wachtwoord\n'
                          '   • SSL/TLS: Ingeschakeld',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://myaccount.google.com/security');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Open Gmail Instellingen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://support.google.com/accounts/answer/185833?hl=nl');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Bekijk Documentatie'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Outlook/Microsoft 365 Sectie
                        Text(
                          'Outlook/Microsoft 365',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Microsoft 365 instellen:\n'
                          '1. Log in op je Microsoft account\n'
                          '2. Ga naar Beveiliging → Geavanceerde beveiliging\n'
                          '3. Maak een app-wachtwoord aan\n'
                          '4. Gebruik deze instellingen:\n'
                          '   • SMTP Server: smtp.office365.com\n'
                          '   • Poort: 587\n'
                          '   • E-mail: je Outlook/Microsoft 365 adres\n'
                          '   • Wachtwoord: het gegenereerde app-wachtwoord\n'
                          '   • SSL/TLS: Ingeschakeld',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://account.microsoft.com/security');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Open Microsoft Instellingen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://support.microsoft.com/nl-nl/office/pop-imap-en-smtp-instellingen-8361e398-8af4-4e97-b147-6c6c4ac95353');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Bekijk Documentatie'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 235, 238, 1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color.fromRGBO(255, 205, 210, 1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color.fromRGBO(211, 47, 47, 1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color.fromRGBO(211, 47, 47, 1)),
                        ),
                      ),
                    ],
                  ),
                ),

              // SMTP Server instellingen
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'SMTP Server *',
                        hintText: 'smtp.gmail.com',
                        helperText: 'Bijvoorbeeld: smtp.gmail.com of smtp.office365.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'SMTP server is verplicht' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Poort *',
                        hintText: '587',
                        helperText: '587 of 465',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Poort is verplicht';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Ongeldige poort';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // E-mail en Wachtwoord
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mailadres *',
                  helperText: 'Het e-mailadres dat je wilt gebruiken voor het versturen van facturen',
                  hintText: 'jouw@emailadres.nl',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'E-mailadres is verplicht';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!)) {
                    return 'Voer een geldig e-mailadres in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'App-wachtwoord *',
                  helperText: 'Gebruik een app-specifiek wachtwoord, niet je normale e-mailwachtwoord',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Wachtwoord is verplicht' : null,
              ),
              const SizedBox(height: 16),

              // SSL/TLS optie
              SwitchListTile(
                title: const Text('Gebruik SSL/TLS'),
                subtitle: const Text(
                  'Schakel beveiligde verbinding in (aanbevolen)',
                ),
                value: _useSSL,
                onChanged: (value) {
                  setState(() {
                    _useSSL = value;
                    _portController.text = value ? '465' : '587';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Automatische e-mail instellingen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(227, 242, 253, 1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromRGBO(187, 222, 251, 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Factuur E-mail Instellingen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Automatisch Versturen'),
                      subtitle: const Text(
                        'Verstuur facturen automatisch naar klanten bij aanmaken of op de vervaldatum',
                      ),
                      value: _autoSendEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoSendEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'E-mail Sjablonen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Je kunt de volgende variabelen gebruiken in je sjablonen:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '{factuurnummer}, {bedrijfsnaam}, {klantnaam}, {factuurdatum}, {vervaldatum}, {totaalbedrag}, {iban}',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectTemplateController,
                      decoration: const InputDecoration(
                        labelText: 'Onderwerp Sjabloon',
                        hintText: 'Factuur {factuurnummer} van {bedrijfsnaam}',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyTemplateController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail Tekst Sjabloon',
                        hintText: 'Geachte {klantnaam},\n\nBijgaand ontvangt u factuur {factuurnummer}...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) =>
                          value?.isEmpty == true ? 'E-mail tekst sjabloon is verplicht' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Test en Opslaan knoppen
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Test Verbinding'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: const Icon(Icons.save),
                    label: const Text('Instellingen Opslaan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
