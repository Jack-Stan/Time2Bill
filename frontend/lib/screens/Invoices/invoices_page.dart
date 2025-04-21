import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/invoice_filter_dialog.dart';
import 'widgets/new_invoice_form.dart';
import 'widgets/recurring_invoice_form.dart';
import 'widgets/recurring_invoice_list.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2; // Invoices tab index
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _invoices = [];
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _statusFilter = 'all';
  
  // Statistics/summary data
  double _totalPaid = 0;
  double _totalUnpaid = 0;
  int _overdueCount = 0;
  int _recurringCount = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInvoices();
    _fetchRecurringCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices');

      // Apply status filter if not "all"
      if (_statusFilter != 'all') {
        query = query.where('status', isEqualTo: _statusFilter);
      }
      
      // Apply sorting
      String orderField = 'invoiceDate';
      if (_sortBy == 'number') orderField = 'invoiceNumber';
      else if (_sortBy == 'amount') orderField = 'total';
      else if (_sortBy == 'client') orderField = 'clientName';
      
      final QuerySnapshot snapshot = await query
          .orderBy(orderField, descending: !_sortAscending)
          .get();

      // Process the data
      var invoices = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'invoiceNumber': data['invoiceNumber'] ?? 'No Invoice Number',
          'clientName': data['clientName'] ?? 'Unknown Client',
          'total': data['total'] ?? 0.0,
          'status': data['status'] ?? 'draft',
          'invoiceDate': data['invoiceDate'] as Timestamp? ?? Timestamp.now(),
          'dueDate': data['dueDate'] as Timestamp? ?? Timestamp.now(),
        };
      }).toList();

      // Apply search filtering in memory if there's a query
      if (_searchQuery.isNotEmpty) {
        final lowercaseQuery = _searchQuery.toLowerCase();
        invoices = invoices.where((invoice) {
          return invoice['invoiceNumber'].toString().toLowerCase().contains(lowercaseQuery) ||
                 invoice['clientName'].toString().toLowerCase().contains(lowercaseQuery);
        }).toList();
      }

      // Calculate summary statistics
      double totalPaid = 0;
      double totalUnpaid = 0;
      int overdueCount = 0;
      final now = DateTime.now();
      
      for (var invoice in invoices) {
        final status = invoice['status'];
        final amount = (invoice['total'] as num).toDouble();
        
        if (status == 'paid') {
          totalPaid += amount;
        } else {
          totalUnpaid += amount;
          
          // Check if overdue
          final dueDate = (invoice['dueDate'] as Timestamp).toDate();
          if (dueDate.isBefore(now) && status != 'paid') {
            overdueCount++;
          }
        }
      }

      setState(() {
        _invoices = invoices;
        _totalPaid = totalPaid;
        _totalUnpaid = totalUnpaid;
        _overdueCount = overdueCount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading invoices: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching invoices: $error');
    }
  }

  Future<void> _fetchRecurringCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recurring_invoices')
          .count()
          .get();

      setState(() {
        _recurringCount = snapshot.count ?? 0;
      });
    } catch (error) {
      print('Error fetching recurring invoice count: $error');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => InvoiceFilterDialog(
        currentSortBy: _sortBy,
        currentSortAscending: _sortAscending,
        currentStatusFilter: _statusFilter,
        onApplyFilters: (sortBy, sortAscending, statusFilter) {
          setState(() {
            _sortBy = sortBy;
            _sortAscending = sortAscending;
            _statusFilter = statusFilter;
          });
          _fetchInvoices();
        },
      ),
    );
  }

  void _showNewInvoiceForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const NewInvoiceForm();
      },
    ).then((_) => _fetchInvoices());
  }

  void _showNewRecurringInvoiceForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const RecurringInvoiceForm();
      },
    ).then((_) => _fetchRecurringCount());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              switch (index) {
                case 0: // Dashboard
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1: // Time Tracking
                  Navigator.pushReplacementNamed(context, '/time-tracking');
                  break;
                case 2: // Invoices (already on this page)
                  setState(() => _selectedIndex = index);
                  break;
                case 3: // Clients
                  Navigator.pushReplacementNamed(context, '/clients');
                  break;
                case 4: // Reports
                  Navigator.pushReplacementNamed(context, '/reports');
                  break;
                case 5: // Settings
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
                case 6: // Projects
                  Navigator.pushReplacementNamed(context, '/projects');
                  break;
                default:
                  setState(() => _selectedIndex = index);
              }
            },
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildHeader(),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Invoices'),
                      Tab(text: 'Recurring'),
                    ],
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Regular Invoices
                        _buildRegularInvoicesTab(),
                        
                        // Tab 2: Recurring Invoices
                        RecurringInvoiceList(
                          onNewRecurringInvoice: _showNewRecurringInvoiceForm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularInvoicesTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildSearchAndFilterBar(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _invoices.isEmpty
                        ? _buildEmptyState()
                        : _buildInvoicesTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Invoices',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showNewRecurringInvoiceForm,
              icon: const Icon(Icons.repeat),
              label: const Text('New Recurring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showNewInvoiceForm,
              icon: const Icon(Icons.add),
              label: const Text('New Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Paid', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moneyFormat.format(_totalPaid),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Unpaid', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moneyFormat.format(_totalUnpaid),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Overdue', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _overdueCount.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.repeat, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Recurring', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recurringCount.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search invoices...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Debounce search for better performance
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == value) {
                  _fetchInvoices();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          label: const Text('Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableHeader(),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _invoices.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  return _buildInvoiceRow(invoice);
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
          flex: 1,
          child: Text('Invoice #', style: headerStyle),
        ),
        Expanded(
          flex: 2,
          child: Text('Client', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Date', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Due Date', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Amount', style: headerStyle),
        ),
        Expanded(
          flex: 1,
          child: Text('Status', style: headerStyle),
        ),
        const SizedBox(width: 50), // Actions column
      ],
    );
  }

  Widget _buildInvoiceRow(Map<String, dynamic> invoice) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    final invoiceDate = (invoice['invoiceDate'] as Timestamp).toDate();
    final dueDate = (invoice['dueDate'] as Timestamp).toDate();
    final total = (invoice['total'] as num).toDouble();
    final status = invoice['status'] as String;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'draft':
        statusColor = Colors.grey;
        statusIcon = Icons.edit_note;
        break;
      case 'sent':
        statusColor = Colors.blue;
        statusIcon = Icons.send;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }
    
    return InkWell(
      onTap: () {
        // Navigate to invoice details page
        // TODO: Implement navigation to invoice detail
        print('View invoice: ${invoice['id']}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                invoice['invoiceNumber'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(invoice['clientName'].toString()),
            ),
            Expanded(
              flex: 1,
              child: Text(dateFormat.format(invoiceDate)),
            ),
            Expanded(
              flex: 1,
              child: Text(dateFormat.format(dueDate)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                moneyFormat.format(total),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    status.substring(0, 1).toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor),
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
                      _showInvoiceActions(invoice);
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

  void _showInvoiceActions(Map<String, dynamic> invoice) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = 
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), 
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18),
              SizedBox(width: 8),
              Text('View'),
            ],
          ),
        ),
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
        const PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 18),
              SizedBox(width: 8),
              Text('Download PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'mark_paid',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18),
              SizedBox(width: 8),
              Text('Mark as Paid'),
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
      elevation: 8,
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'view':
          // TODO: Navigate to invoice detail page
          break;
        case 'edit':
          // TODO: Open edit invoice form
          break;
        case 'download':
          // TODO: Generate and download PDF
          break;
        case 'mark_paid':
          _markInvoiceAsPaid(invoice['id']);
          break;
        case 'delete':
          _showDeleteConfirmation(invoice['id']);
          break;
      }
    });
  }

  Future<void> _markInvoiceAsPaid(String invoiceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .update({'status': 'paid'});
          
      _fetchInvoices();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice marked as paid')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating invoice: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String invoiceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteInvoice(invoiceId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .doc(invoiceId)
          .delete();
          
      _fetchInvoices();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting invoice: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Invoices Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewInvoiceForm,
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
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
            onPressed: _fetchInvoices,
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
