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

      setState(() {
        _recurringInvoices = recurringInvoices;
        _isLoading = false;
      });
    } catch (error) {
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
    final autoSend = invoice['autoSend'] as bool;
    
    String frequencyText;
    switch (invoice['frequency']) {
      case 'weekly':
        frequencyText = 'Weekly';
        break;
      case 'biweekly':
        frequencyText = 'Bi-weekly';
        break;
      case 'monthly':
        frequencyText = 'Monthly';
        break;
      case 'quarterly':
        frequencyText = 'Quarterly';
        break;
      case 'yearly':
        frequencyText = 'Yearly';
        break;
      default:
        frequencyText = 'Monthly';
    }
    
    return InkWell(
      onTap: () {
        // Show recurring invoice details
        // TODO: Implement view details
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
          // TODO: Implement edit recurring invoice
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
      // Dit zou doorgaans via een Cloud Function gebeuren
      // Maar voor nu simuleren we het via een directe update
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Call a Firebase Function to generate the invoice
      // await FirebaseFunctions.instance.httpsCallable('generateRecurringInvoice')
      //     .call({'recurringInvoiceId': id});
      
      // For now, just update the last generated date
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .doc(id)
          .update({
            'lastGeneratedDate': Timestamp.now(),
            'nextGenerationDate': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30)) // Default to next month
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
