import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/client_model.dart';
import '../../../models/invoice_model.dart';
import '../../../services/firebase_service.dart';

class NewInvoiceForm extends StatefulWidget {
  final String? invoiceId;
  final bool isEditing;
  final VoidCallback? onInvoiceSaved;

  const NewInvoiceForm({
    super.key, 
    this.invoiceId,
    this.isEditing = false,
    this.onInvoiceSaved,
  });

  @override
  State<NewInvoiceForm> createState() => _NewInvoiceFormState();
}

class _NewInvoiceFormState extends State<NewInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Invoice data
  String? _selectedClientId;
  List<ClientModel> _clients = [];
  String? _selectedProjectId;
  List<Map<String, dynamic>> _projects = [];
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<InvoiceLineItem> _lineItems = [];
  
  // Controllers
  final _invoiceNumberController = TextEditingController();
  final _noteController = TextEditingController();
  final _vatRateController = TextEditingController(text: '21');
  
  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing && widget.invoiceId != null) {
      _loadInvoiceData();
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _noteController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading data for invoice form...');
      
      // Get next invoice number
      await _generateInvoiceNumber();
      
      // Load clients
      try {
        final clients = await _firebaseService.getClients();
        setState(() {
          _clients = clients;
        });
        print('Successfully loaded ${clients.length} clients');
      } catch (e) {
        print('Error loading clients via service: $e');
        _loadClientsDirectly();
      }
      
      // Load projects
      try {
        final projects = await _firebaseService.getProjects();
        setState(() {
          _projects = projects.map((p) => {
            'id': p.id,
            'title': p.title,
            'clientId': p.clientId,
          }).toList();
        });
        print('Successfully loaded ${projects.length} projects');
      } catch (e) {
        print('Error loading projects via service: $e');
        _loadProjectsDirectly();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        _errorMessage = 'Failed to load required data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(widget.invoiceId)
          .get();

      if (!doc.exists) {
        throw Exception('Invoice not found');
      }

      final data = doc.data()!;
      
      // Populate form fields with existing data
      _invoiceNumberController.text = data['invoiceNumber'] ?? '';
      _invoiceDate = (data['invoiceDate'] as Timestamp).toDate();
      _dueDate = (data['dueDate'] as Timestamp).toDate();
      
      // Set selected client
      _selectedClientId = data['clientId'] as String?;
      
      // Set project
      _selectedProjectId = data['projectId'] as String?;
      
      // Load items
      final items = data['lineItems'] as List<dynamic>? ?? [];
      _lineItems.clear();
      _lineItems.addAll(items.map((item) => InvoiceLineItem.fromMap(item as Map<String, dynamic>)).toList());
      
      // Set notes
      _noteController.text = data['note'] as String? ?? '';
      
      // Set VAT rate
      _vatRateController.text = (data['vatRate'] as num?)?.toString() ?? '21';
      
    } catch (e) {
      _errorMessage = 'Error loading invoice: $e';
      print('Error loading invoice: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClientsDirectly() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .get();
          
      final clients = snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
      
      setState(() {
        _clients = clients;
      });
      print('Successfully loaded ${clients.length} clients directly');
    } catch (e) {
      print('Error loading clients directly: $e');
      setState(() {
        _errorMessage = 'Failed to load clients: ${e.toString()}';
      });
    }
  }

  Future<void> _loadProjectsDirectly() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .get();
          
      final projects = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Unnamed Project',
          'clientId': data['clientId'] ?? '',
        };
      }).toList();
      
      setState(() {
        _projects = projects;
      });
      print('Successfully loaded ${projects.length} projects directly');
    } catch (e) {
      print('Error loading projects directly: $e');
    }
  }

  Future<void> _generateInvoiceNumber() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Get current year
      final currentYear = DateTime.now().year;
      
      // Check for existing invoice number pattern in database
      final invoices = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('invoiceNumber', isGreaterThanOrEqualTo: '$currentYear-')
          .where('invoiceNumber', isLessThan: '${currentYear+1}-')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();
      
      String newInvoiceNumber;
      
      if (invoices.docs.isNotEmpty) {
        // Extract last invoice number and increment
        final lastInvoiceNumber = invoices.docs.first['invoiceNumber'] as String;
        final parts = lastInvoiceNumber.split('-');
        if (parts.length == 2) {
          final lastNumber = int.tryParse(parts[1]) ?? 0;
          newInvoiceNumber = '$currentYear-${(lastNumber + 1).toString().padLeft(3, '0')}';
        } else {
          newInvoiceNumber = '$currentYear-001';
        }
      } else {
        // No invoices for this year yet
        newInvoiceNumber = '$currentYear-001';
      }
      
      setState(() {
        _invoiceNumberController.text = newInvoiceNumber;
      });
      
      print('Generated invoice number: $newInvoiceNumber');
    } catch (e) {
      print('Error generating invoice number: $e');
      // Default number if failed
      _invoiceNumberController.text = '${DateTime.now().year}-001';
    }
  }

  void _addEmptyLineItem() {
    setState(() {
      _lineItems.add(
        InvoiceLineItem(
          description: '',
          quantity: 1,
          unitPrice: 0,
          amount: 0,
        ),
      );
    });
  }

  void _updateLineItem(int index, {
    String? description,
    double? quantity,
    double? unitPrice,
  }) {
    if (index < 0 || index >= _lineItems.length) return;
    
    setState(() {
      final item = _lineItems[index];
      
      final updatedDescription = description ?? item.description;
      final updatedQuantity = quantity ?? item.quantity;
      final updatedUnitPrice = unitPrice ?? item.unitPrice;
      final updatedAmount = updatedQuantity * updatedUnitPrice;
      
      _lineItems[index] = InvoiceLineItem(
        description: updatedDescription,
        quantity: updatedQuantity,
        unitPrice: updatedUnitPrice,
        amount: updatedAmount,
      );
    });
  }

  void _removeLineItem(int index) {
    if (index < 0 || index >= _lineItems.length) return;
    
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  double get _subtotal {
    return _lineItems.fold(0, (sum, item) => sum + item.amount);
  }

  double get _vatAmount {
    final vatRate = double.tryParse(_vatRateController.text) ?? 21;
    return _subtotal * (vatRate / 100);
  }

  double get _total {
    return _subtotal + _vatAmount;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }
    
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Find client info
      final client = _clients.firstWhere(
        (c) => c.id == _selectedClientId,
        orElse: () => throw Exception('Selected client not found'),
      );
      
      // Create invoice model
      final invoice = InvoiceModel(
        invoiceNumber: _invoiceNumberController.text,
        clientId: _selectedClientId!,
        clientName: client.name,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        lineItems: _lineItems,
        subtotal: _subtotal,
        vatRate: double.tryParse(_vatRateController.text) ?? 21,
        vatAmount: _vatAmount,
        total: _total,
        status: 'draft',
        projectId: _selectedProjectId,
      );
      
      if (widget.isEditing && widget.invoiceId != null) {
        // Update existing invoice
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('invoices')
            .doc(widget.invoiceId)
            .update(invoice.toMap());
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice updated successfully')),
          );
        }
      } else {
        // Save to Firebase
        String invoiceId;
        try {
          print('Saving invoice using Firebase Service...');
          invoiceId = await _firebaseService.addInvoice(invoice);
          print('Invoice saved successfully with ID: $invoiceId');
        } catch (e) {
          print('Error saving invoice via service: $e');
          
          // Fallback to direct Firestore save
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception('User not authenticated');
          
          final docRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('invoices')
              .add(invoice.toMap());
              
          invoiceId = docRef.id;
          print('Invoice saved directly with ID: $invoiceId');
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice #${_invoiceNumberController.text} created successfully')),
        );
      }
      
      // Call the callback if provided
      widget.onInvoiceSaved?.call();
      
      // Close the dialog
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save invoice: ${e.toString()}';
        _isLoading = false;
      });
      print('Error saving invoice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Invoice' : 'Create New Invoice';
    
    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxWidth: 900),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF0B5394),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade900),
                                ),
                              ),
                            
                            // Invoice details section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column - Client & Basic Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Client dropdown
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Client *',
                                          border: OutlineInputBorder(),
                                        ),
                                        value: _selectedClientId,
                                        items: _clients.map((client) {
                                          return DropdownMenuItem<String>(
                                            value: client.id,
                                            child: Text(
                                              client.companyName.isNotEmpty
                                                  ? '${client.name} (${client.companyName})'
                                                  : client.name,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedClientId = value;
                                            // Reset project if it doesn't belong to this client
                                            if (_selectedProjectId != null) {
                                              final projectBelongsToClient = _projects.any((p) => 
                                                p['id'] == _selectedProjectId && 
                                                p['clientId'] == value);
                                                
                                              if (!projectBelongsToClient) {
                                                _selectedProjectId = null;
                                              }
                                            }
                                          });
                                        },
                                        validator: (value) => 
                                          value == null ? 'Please select a client' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Project dropdown (optional)
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Project (Optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                        value: _selectedProjectId,
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('No Project'),
                                          ),
                                          ..._projects
                                            .where((p) => _selectedClientId == null || 
                                                  p['clientId'] == _selectedClientId)
                                            .map((project) {
                                              return DropdownMenuItem<String>(
                                                value: project['id'],
                                                child: Text(project['title']),
                                              );
                                            }).toList(),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedProjectId = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right column - Invoice Dates & Number
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Invoice Number
                                      TextFormField(
                                        controller: _invoiceNumberController,
                                        decoration: const InputDecoration(
                                          labelText: 'Invoice Number *',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => 
                                          value?.isEmpty ?? true 
                                            ? 'Please enter an invoice number' 
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      // Invoice Date
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _invoiceDate,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _invoiceDate = date;
                                              // Update due date based on invoice date
                                              _dueDate = date.add(const Duration(days: 30));
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Invoice Date *',
                                            border: OutlineInputBorder(),
                                            suffixIcon: Icon(Icons.calendar_today),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(_invoiceDate),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Due Date
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _dueDate,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _dueDate = date;
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Due Date *',
                                            border: OutlineInputBorder(),
                                            suffixIcon: Icon(Icons.calendar_today),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(_dueDate),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Line Items Section
                            const Text(
                              'Line Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Line Items Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              color: Colors.grey[200],
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text('Description'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Quantity', textAlign: TextAlign.right),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Unit Price', textAlign: TextAlign.right),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Amount', textAlign: TextAlign.right),
                                  ),
                                  SizedBox(width: 40),
                                ],
                              ),
                            ),
                            
                            // Line Items
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _lineItems.length,
                              itemBuilder: (context, index) {
                                final item = _lineItems[index];
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Description
                                      Expanded(
                                        flex: 5,
                                        child: TextFormField(
                                          initialValue: item.description,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) => _updateLineItem(
                                            index,
                                            description: value,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Quantity
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          initialValue: item.quantity.toString(),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                          textAlign: TextAlign.right,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            final quantity = double.tryParse(value) ?? 0;
                                            _updateLineItem(
                                              index,
                                              quantity: quantity,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Unit Price
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.unitPrice.toString(),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            prefixText: '€ ',
                                          ),
                                          textAlign: TextAlign.right,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            final unitPrice = double.tryParse(value) ?? 0;
                                            _updateLineItem(
                                              index,
                                              unitPrice: unitPrice,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Amount
                                      Expanded(
                                        flex: 2,
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                          child: Text(
                                            '€ ${item.amount.toStringAsFixed(2)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Delete Button
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeLineItem(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            // Add Line Item Button
                            OutlinedButton.icon(
                              onPressed: _addEmptyLineItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Line Item'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0B5394),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Totals Section
                            Row(
                              children: [
                                // Notes
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _noteController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Payment terms, thank you note, etc.',
                                        ),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Totals
                                Expanded(
                                  flex: 2,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Subtotal:'),
                                              Text(
                                                '€ ${_subtotal.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('VAT '),
                                                  SizedBox(
                                                    width: 50,
                                                    child: TextFormField(
                                                      controller: _vatRateController,
                                                      decoration: const InputDecoration(
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        border: OutlineInputBorder(),
                                                        suffixText: '%',
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          // Just trigger rebuilding for totals recalculation
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const Text(':'),
                                                ],
                                              ),
                                              Text(
                                                '€ ${_vatAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '€ ${_total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF0B5394),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5394),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.isEditing ? 'Update Invoice' : 'Create Invoice'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
