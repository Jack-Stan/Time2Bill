import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RecurringInvoiceForm extends StatefulWidget {
  final Map<String, dynamic>? editRecurringInvoice;

  const RecurringInvoiceForm({
    super.key,
    this.editRecurringInvoice,
  });

  @override
  State<RecurringInvoiceForm> createState() => _RecurringInvoiceFormState();
}

class _RecurringInvoiceFormState extends State<RecurringInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  String? _errorMessage;
  
  // Client list
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;
  String? _selectedClientId;
  
  // Form fields
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vatRateController = TextEditingController(text: '21');
  
  // Invoice configuration
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _frequency = 'monthly';
  bool _autoSend = false;
  bool _hasEndDate = false;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    
    if (widget.editRecurringInvoice != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final invoice = widget.editRecurringInvoice!;
    
    setState(() {
      _selectedClientId = invoice['clientId'];
      _descriptionController.text = invoice['description'] ?? '';
      _amountController.text = (invoice['amount'] as num?)?.toString() ?? '0.0';
      _vatRateController.text = (invoice['vatRate'] as num?)?.toString() ?? '21';
      
      if (invoice['startDate'] != null) {
        _startDate = (invoice['startDate'] as Timestamp).toDate();
      }
      
      if (invoice['endDate'] != null) {
        _endDate = (invoice['endDate'] as Timestamp).toDate();
        _hasEndDate = true;
      }
      
      _frequency = invoice['frequency'] ?? 'monthly';
      _autoSend = invoice['autoSend'] ?? false;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .orderBy('name')
          .get();

      final clients = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Client',
          'email': data['email'] ?? '',
          'vatNumber': data['vatNumber'] ?? '',
        };
      }).toList();

      setState(() {
        _clients = clients;
        _loadingClients = false;
      });
    } catch (error) {
      setState(() {
        _loadingClients = false;
        _errorMessage = 'Failed to load clients: ${error.toString()}';
      });
    }
  }

  Future<void> _saveRecurringInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      setState(() {
        _errorMessage = 'Please select a client';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Bereken volgende factuurdatum op basis van frequentie
      DateTime nextDate = _calculateNextInvoiceDate(_startDate, _frequency);

      // Get selected client data
      final selectedClient = _clients.firstWhere(
        (client) => client['id'] == _selectedClientId,
        orElse: () => {'name': 'Unknown Client'},
      );
      
      // Prepare recurring invoice data
      final recurringInvoiceData = {
        'clientId': _selectedClientId,
        'clientName': selectedClient['name'],
        'description': _descriptionController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'vatRate': double.tryParse(_vatRateController.text) ?? 21.0,
        'frequency': _frequency,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': _hasEndDate && _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'nextGenerationDate': Timestamp.fromDate(nextDate),
        'autoSend': _autoSend,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final recurringInvoicesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices');
      
      if (widget.editRecurringInvoice != null) {
        // Update existing recurring invoice
        await recurringInvoicesRef.doc(widget.editRecurringInvoice!['id']).update(recurringInvoiceData);
      } else {
        // Create new recurring invoice
        await recurringInvoicesRef.add(recurringInvoiceData);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      
      final action = widget.editRecurringInvoice != null ? 'updated' : 'created';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recurring invoice successfully $action')),
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to save recurring invoice: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  DateTime _calculateNextInvoiceDate(DateTime startDate, String frequency) {
    // Als startdatum in het verleden is, berekenen we vanaf vandaag
    final baseDate = startDate.isBefore(DateTime.now()) ? DateTime.now() : startDate;
    
    switch (frequency) {
      case 'weekly':
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 7);
      case 'biweekly':
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 14);
      case 'monthly':
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      case 'quarterly':
        return DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
      case 'yearly':
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
      default:
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day); // Default to monthly
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editRecurringInvoice != null;
    final title = isEditing ? 'Edit Recurring Invoice' : 'Create Recurring Invoice';
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
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
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                      Colors.red.r.toInt(),
                      Colors.red.g.toInt(),
                      Colors.red.b.toInt(),
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client selection
                      const Text(
                        'Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildClientSelector(),
                      const SizedBox(height: 24),
                      
                      // Invoice details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Monthly Rent for Office Space',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Amount
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    prefixText: '€ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // VAT Rate
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VAT Rate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _vatRateController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '21',
                                    suffixText: '%',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final rate = double.tryParse(value);
                                    if (rate == null || rate < 0 || rate > 100) {
                                      return 'Invalid rate';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Recurrence settings
                      const Text(
                        'Recurrence Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Frequency
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Frequency'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _frequency,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                    DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _frequency = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Start date
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _startDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                                        const Icon(Icons.calendar_today, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // End date
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('End Date'),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: _hasEndDate,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasEndDate = value;
                                          if (value && _endDate == null) {
                                            _endDate = DateTime.now().add(const Duration(days: 365));
                                          }
                                        });
                                      },
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _hasEndDate ? () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _endDate = date;
                                      });
                                    }
                                  } : null,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabled: _hasEndDate,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_hasEndDate && _endDate != null ? 
                                          DateFormat('dd/MM/yyyy').format(_endDate!) : 
                                          'No end date'),
                                        Icon(Icons.calendar_today, 
                                          size: 18, 
                                          color: _hasEndDate ? null : Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Automatic sending
                      SwitchListTile(
                        title: const Text(
                          'Automatic Sending',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'When enabled, invoices will be generated and sent automatically by email',
                        ),
                        value: _autoSend,
                        onChanged: (value) {
                          setState(() {
                            _autoSend = value;
                          });
                        },
                        activeColor: primaryColor,
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
                    onPressed: _isLoading ? null : _saveRecurringInvoice,
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
                        : const Text('Save Recurring Invoice'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    if (_loadingClients) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No clients available'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to client creation
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/clients');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedClientId,
              isExpanded: true,
              hint: const Text('Select Client'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a client';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedClientId = value;
                });
              },
              items: _clients.map((client) {
                return DropdownMenuItem<String>(
                  value: client['id'],
                  child: Text(client['name']),
                );
              }).toList(),
            ),
          ),
        ),
        if (_selectedClientId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clients.firstWhere((c) => c['id'] == _selectedClientId)['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_clients.firstWhere((c) => c['id'] == _selectedClientId)['email']),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
