import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecurringInvoiceList extends StatefulWidget {
  final VoidCallback onNewRecurringInvoice;

  const RecurringInvoiceList({
    super.key,
    required this.onNewRecurringInvoice,
  });

  @override
  State<RecurringInvoiceList> createState() => _RecurringInvoiceListState();
}

class _RecurringInvoiceListState extends State<RecurringInvoiceList> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _recurringInvoices = [];
  final Color primaryColor = const Color(0xFF0B5394);

  @override
  void initState() {
    super.initState();
    _fetchRecurringInvoices();
  }

  Future<void> _fetchRecurringInvoices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .orderBy('nextGenerationDate', descending: false)
          .get();

      final recurringInvoices = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'clientName': data['clientName'] ?? 'Unknown Client',
          'description': data['description'] ?? 'No description',
          'amount': data['amount'] ?? 0.0,
          'frequency': data['frequency'] ?? 'monthly',
          'nextGenerationDate': data['nextGenerationDate'] as Timestamp? ?? Timestamp.now(),
          'startDate': data['startDate'] as Timestamp? ?? Timestamp.now(),
          'endDate': data['endDate'] as Timestamp?,
          'autoSend': data['autoSend'] ?? false,
          'active': data['active'] ?? true,
          'lastGeneratedDate': data['lastGeneratedDate'] as Timestamp?,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _recurringInvoices = recurringInvoices;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading recurring invoices: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching recurring invoices: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _recurringInvoices.isEmpty
                        ? _buildEmptyState()
                        : _buildRecurringInvoicesTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recurring Invoices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up recurring invoices for regular services or rentals. Invoices will be automatically generated according to the schedule you define.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onNewRecurringInvoice,
              icon: const Icon(Icons.add),
              label: const Text('New Recurring Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringInvoicesTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _recurringInvoices.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final invoice = _recurringInvoices[index];
                  return _buildRecurringInvoiceRow(invoice);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    TextStyle headerStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('Client', style: headerStyle),
        ),
        Expanded(
          flex: 2,
          child: Text('Description', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Amount', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Frequency', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Next Date', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Status', style: headerStyle),
        ),
        const SizedBox(width: 50), // Actions column
      ],
    );
  }

  Widget _buildRecurringInvoiceRow(Map<String, dynamic> invoice) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    final nextDate = (invoice['nextGenerationDate'] as Timestamp).toDate();
    final amount = (invoice['amount'] as num).toDouble();
    final isActive = invoice['active'] as bool;
    
    String frequencyText = _getFrequencyText(invoice['frequency']);
    
    return InkWell(
      onTap: () {
        _showRecurringInvoiceDetails(invoice);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(invoice['clientName']),
            ),
            Expanded(
              flex: 2,
              child: Text(
                invoice['description'],
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                moneyFormat.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(frequencyText),
            ),
            Expanded(
              flex: 1,
              child: Text(dateFormat.format(nextDate)),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isActive ? 'Active' : 'Paused',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 50,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () {
                      _showRecurringInvoiceActions(invoice);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecurringInvoiceDetails(Map<String, dynamic> invoice) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recurring Invoice Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Client', invoice['clientName']),
              _buildDetailRow('Description', invoice['description']),
              _buildDetailRow('Amount', 
                NumberFormat.currency(locale: 'nl_NL', symbol: '€').format(
                  (invoice['amount'] as num).toDouble()
                )
              ),
              _buildDetailRow('Status', invoice['active'] ? 'Active' : 'Paused'),
              _buildDetailRow('Frequency', _getFrequencyText(invoice['frequency'])),
              _buildDetailRow('Auto-send', invoice['autoSend'] ? 'Yes' : 'No'),
              _buildDetailRow('Next Generation', 
                dateFormat.format((invoice['nextGenerationDate'] as Timestamp).toDate())
              ),
              if (invoice['lastGeneratedDate'] != null)
                _buildDetailRow('Last Generated', 
                  dateFormat.format((invoice['lastGeneratedDate'] as Timestamp).toDate())
                ),
              _buildDetailRow('Start Date', 
                dateFormat.format((invoice['startDate'] as Timestamp).toDate())
              ),
              if (invoice['endDate'] != null)
                _buildDetailRow('End Date', 
                  dateFormat.format((invoice['endDate'] as Timestamp).toDate())
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _editRecurringInvoice(invoice);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
    }
  }

  void _editRecurringInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) {
        final clientNameController = TextEditingController(text: invoice['clientName']);
        final descriptionController = TextEditingController(text: invoice['description']);
        final amountController = TextEditingController(
          text: (invoice['amount'] as num).toDouble().toString()
        );
        final formKey = GlobalKey<FormState>();
        String frequency = invoice['frequency'];
        bool autoSend = invoice['autoSend'];
        
        return AlertDialog(
          title: const Text('Edit Recurring Invoice'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                      value == null || value.isEmpty ? 'Client name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                      value == null || value.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
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
                        frequency = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Auto-send invoice'),
                    value: autoSend,
                    onChanged: (value) {
                      autoSend = value ?? false;
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop();
                  _updateRecurringInvoice(
                    invoice['id'],
                    {
                      'clientName': clientNameController.text,
                      'description': descriptionController.text,
                      'amount': double.parse(amountController.text),
                      'frequency': frequency,
                      'autoSend': autoSend,
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRecurringInvoice(String id, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .doc(id)
          .update(data);
          
      _fetchRecurringInvoices();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring invoice updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating recurring invoice: $e')),
      );
    }
  }

  void _showRecurringInvoiceActions(Map<String, dynamic> invoice) {
    final bool isActive = invoice['active'] as bool;
    
    showMenu(
      context: context,
      position: RelativeRect.fill,
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: isActive ? 'pause' : 'activate',
          child: Row(
            children: [
              Icon(
                isActive ? Icons.pause : Icons.play_arrow,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(isActive ? 'Pause' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'generate_now',
          child: Row(
            children: [
              Icon(Icons.send, size: 18),
              SizedBox(width: 8),
              Text('Generate Now'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'edit':
          _editRecurringInvoice(invoice);
          break;
        case 'pause':
          _updateRecurringInvoiceStatus(invoice['id'], false);
          break;
        case 'activate':
          _updateRecurringInvoiceStatus(invoice['id'], true);
          break;
        case 'generate_now':
          _generateInvoiceNow(invoice['id']);
          break;
        case 'delete':
          _showDeleteConfirmation(invoice['id']);
          break;
      }
    });
  }

  Future<void> _updateRecurringInvoiceStatus(String id, bool active) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .doc(id)
          .update({'active': active});
          
      _fetchRecurringInvoices();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(active 
          ? 'Recurring invoice activated' 
          : 'Recurring invoice paused')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating recurring invoice: $e')),
      );
    }
  }

  Future<void> _generateInvoiceNow(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .doc(id)
          .update({
            'lastGeneratedDate': Timestamp.now(),
            'nextGenerationDate': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30))
            ),
          });
          
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice generated successfully')),
      );
      
      _fetchRecurringInvoices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating invoice: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Invoice'),
        content: const Text(
          'Are you sure you want to delete this recurring invoice? This will not delete any previously generated invoices.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRecurringInvoice(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecurringInvoice(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .doc(id)
          .delete();
          
      _fetchRecurringInvoices();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring invoice deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting recurring invoice: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Recurring Invoices',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first recurring invoice to automate your billing',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onNewRecurringInvoice,
            icon: const Icon(Icons.add),
            label: const Text('Setup Recurring Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRecurringInvoices,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
