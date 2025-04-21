import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientForm extends StatefulWidget {
  final Map<String, dynamic>? client;
  final VoidCallback onClientSaved;

  const ClientForm({
    super.key,
    this.client,
    required this.onClientSaved,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  String? _errorMessage;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Pre-fill form if editing
    if (widget.client != null) {
      _nameController.text = widget.client!['name'] ?? '';
      _emailController.text = widget.client!['email'] ?? '';
      _phoneController.text = widget.client!['phone'] ?? '';
      _addressController.text = widget.client!['address'] ?? '';
      _vatNumberController.text = widget.client!['vatNumber'] ?? '';
      _companyNameController.text = widget.client!['companyName'] ?? '';
      _contactPersonController.text = widget.client!['contactPerson'] ?? '';
      _notesController.text = widget.client!['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vatNumberController.dispose();
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final clientData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'vatNumber': _vatNumberController.text,
        'companyName': _companyNameController.text,
        'contactPerson': _contactPersonController.text,
        'notes': _notesController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final clientsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients');

      if (widget.client != null) {
        // Update existing client
        await clientsRef.doc(widget.client!['id']).update(clientData);
      } else {
        // Add created timestamp for new clients
        clientData['createdAt'] = FieldValue.serverTimestamp();
        
        // Create new client
        await clientsRef.add(clientData);
      }

      widget.onClientSaved();

      if (!mounted) return;
      Navigator.of(context).pop();

      final action = widget.client != null ? 'updated' : 'created';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client successfully $action')),
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to save client: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;
    final title = isEditing ? 'Edit Client' : 'Add New Client';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal/company toggle
                      const Text(
                        'Client Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Basic info section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Client Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Client name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Email
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && 
                                    !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone and Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phone
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // VAT Number
                          Expanded(
                            child: TextFormField(
                              controller: _vatNumberController,
                              decoration: const InputDecoration(
                                labelText: 'VAT Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Company section
                      const Text(
                        'Company Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Company name and contact person
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company name
                          Expanded(
                            child: TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Contact person
                          Expanded(
                            child: TextFormField(
                              controller: _contactPersonController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          hintText: 'Additional information about this client',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(isEditing ? 'Update Client' : 'Add Client'),
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
