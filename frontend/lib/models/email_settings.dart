import 'package:cloud_firestore/cloud_firestore.dart';

class EmailSettings {
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;
  final String smtpEmail;
  final String smtpPassword;
  final bool autoSendEnabled;
  final String defaultSubjectTemplate;
  final String defaultBodyTemplate;
  // PGP encryption settings
  final bool signExternalMessages;
  final bool attachPublicKey;
  final String pgpScheme;
  final String? pgpFingerprint;

  EmailSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecure,
    required this.smtpEmail,
    required this.smtpPassword,
    this.autoSendEnabled = false,
    this.defaultSubjectTemplate = 'Factuur {invoiceNumber} van {companyName}',
    this.defaultBodyTemplate = '''Beste {clientName},

Hierbij ontvangt u factuur {invoiceNumber}.

Factuurgegevens:
- Factuurnummer: {invoiceNumber}
- Factuurdatum: {invoiceDate}
- Vervaldatum: {dueDate}
- Bedrag: €{total}

U kunt de factuur als PDF-bijlage in deze e-mail vinden.

Betaling kunt u overmaken naar:
{iban}
o.v.v. factuurnummer {invoiceNumber}

Met vriendelijke groet,
{companyName}''',
    this.signExternalMessages = false,
    this.attachPublicKey = false,
    this.pgpScheme = 'PGP/MIME',
    this.pgpFingerprint,
  });

  static bool isValidPgpFingerprint(String? fingerprint) {
    if (fingerprint == null) return false;
    return RegExp(r'^[A-Fa-f0-9]{40}$').hasMatch(fingerprint);
  }

  bool validate() {
    if (signExternalMessages && !isValidPgpFingerprint(pgpFingerprint)) {
      throw Exception('Invalid PGP fingerprint format');
    }
    if (signExternalMessages && !['PGP/MIME', 'PGP/Inline'].contains(pgpScheme)) {
      throw Exception('Invalid PGP scheme');
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    validate();
    return {
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smtpSecure': smtpSecure,
      'smtpEmail': smtpEmail,
      'smtpPassword': smtpPassword,
      'autoSendEnabled': autoSendEnabled,
      'defaultSubjectTemplate': defaultSubjectTemplate,
      'defaultBodyTemplate': defaultBodyTemplate,
      'signExternalMessages': signExternalMessages,
      'attachPublicKey': attachPublicKey,
      'pgpScheme': pgpScheme,
      'pgpFingerprint': signExternalMessages ? pgpFingerprint : null,
    };
  }

  static EmailSettings fromMap(Map<String, dynamic> map) {
    return EmailSettings(
      smtpHost: map['smtpHost'] ?? '',
      smtpPort: map['smtpPort'] ?? 587,
      smtpSecure: map['smtpSecure'] ?? false,
      smtpEmail: map['smtpEmail'] ?? '',
      smtpPassword: map['smtpPassword'] ?? '',
      autoSendEnabled: map['autoSendEnabled'] ?? false,
      defaultSubjectTemplate: map['defaultSubjectTemplate'] ?? 'Factuur {invoiceNumber} van {companyName}',
      defaultBodyTemplate: map['defaultBodyTemplate'],
      signExternalMessages: map['signExternalMessages'] ?? false,
      attachPublicKey: map['attachPublicKey'] ?? false,
      pgpScheme: map['pgpScheme'] ?? 'PGP/MIME',
      pgpFingerprint: map['pgpFingerprint'],
    );
  }

  static EmailSettings fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return fromMap(data);
  }
}
