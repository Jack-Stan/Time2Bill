class BusinessDetails {
  final String companyName;
  final String kboNumber;
  final String vatNumber;
  final String address;
  final String legalForm;
  final String iban;
  final int defaultVatRate;
  final int paymentTerms;
  final String? peppolId;
  final String? phone;
  final String? website;

  BusinessDetails({
    required this.companyName,
    required this.kboNumber,
    required this.vatNumber,
    required this.address,
    required this.legalForm,
    required this.iban,
    required this.defaultVatRate,
    required this.paymentTerms,
    this.peppolId,
    this.phone,
    this.website,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'kboNumber': kboNumber,
        'vatNumber': vatNumber,
        'address': address,
        'legalForm': legalForm,
        'iban': iban,
        'defaultVatRate': defaultVatRate,
        'paymentTerms': paymentTerms,
        'peppolId': peppolId,
        'phone': phone,
        'website': website,
      };

  factory BusinessDetails.fromJson(Map<String, dynamic> json) => BusinessDetails(
        companyName: json['companyName'],
        kboNumber: json['kboNumber'],
        vatNumber: json['vatNumber'],
        address: json['address'],
        legalForm: json['legalForm'],
        iban: json['iban'],
        defaultVatRate: json['defaultVatRate'],
        paymentTerms: json['paymentTerms'],
        peppolId: json['peppolId'],
        phone: json['phone'],
        website: json['website'],
      );
}
