import 'package:flutter/material.dart';

class BusinessSettingsCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;

  const BusinessSettingsCard({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<BusinessSettingsCard> createState() => _BusinessSettingsCardState();
}

class _BusinessSettingsCardState extends State<BusinessSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _vatRateController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _businessNameController.text = widget.userData['businessName'] ?? '';
    _vatNumberController.text = widget.userData['vatNumber'] ?? '';
    _addressController.text = widget.userData['address'] ?? '';
    _vatRateController.text = (widget.userData['defaultVatRate'] ?? 21).toString();
  }

  @override
  void didUpdateWidget(BusinessSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData != widget.userData) {
      _initializeFields();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _vatNumberController.dispose();
    _addressController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _saveBusinessSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse VAT rate to double, default to 21 if parsing fails
      final vatRate = double.tryParse(_vatRateController.text) ?? 21.0;
      
      final settings = {
        'businessName': _businessNameController.text,
        'vatNumber': _vatNumberController.text,
        'address': _addressController.text,
        'defaultVatRate': vatRate,
      };
      
      await widget.onSave(settings);
      
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.business, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your business information for invoices',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // VAT Number and Default VAT Rate
              Row(
                children: [
                  // VAT Number
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _vatNumberController,
                      decoration: const InputDecoration(
                        labelText: 'VAT Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Default VAT Rate
                  Expanded(
                    child: TextFormField(
                      controller: _vatRateController,
                      decoration: const InputDecoration(
                        labelText: 'Default VAT Rate (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final number = double.tryParse(value);
                        if (number == null || number < 0 || number > 100) {
                          return 'Invalid rate';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  border: OutlineInputBorder(),
                  hintText: 'Street, City, Postal Code, Country',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _saveBusinessSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B5394),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
