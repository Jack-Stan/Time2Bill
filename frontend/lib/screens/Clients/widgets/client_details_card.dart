import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDetailsCard extends StatefulWidget {
  final Map<String, dynamic> client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClientDetailsCard({
    super.key,
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ClientDetailsCard> createState() => _ClientDetailsCardState();
}

class _ClientDetailsCardState extends State<ClientDetailsCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  
  // Statistics
  int _projectCount = 0;
  int _invoiceCount = 0;
  double _totalInvoiced = 0;
  double _totalPaid = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClientStats();
  }
  
  @override
  void didUpdateWidget(ClientDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client['id'] != widget.client['id']) {
      _fetchClientStats();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchClientStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final clientId = widget.client['id'];
      
      // Fetch project count
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .count()
          .get();
          
      // Fetch invoices
      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .get();
          
      // Calculate invoice statistics
      double totalInvoiced = 0;
      double totalPaid = 0;
      
      for (final doc in invoicesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total'] as num?)?.toDouble() ?? 0.0;
        totalInvoiced += amount;
        
        if (data['status'] == 'paid') {
          totalPaid += amount;
        }
      }
      
      setState(() {
        _projectCount = projectsSnapshot.count ?? 0;
        _invoiceCount = invoicesSnapshot.size;
        _totalInvoiced = totalInvoiced;
        _totalPaid = totalPaid;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching client stats: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientHeader(),
          const Divider(height: 1),
          _buildClientInfo(),
          const Divider(height: 1),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Projects'),
              Tab(text: 'Invoices'),
            ],
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProjectsTab(),
                _buildInvoicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: 24,
                child: Text(
                  widget.client['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.client['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.client['companyName'].isNotEmpty)
                    Text(
                      widget.client['companyName'],
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Client',
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete Client',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.client['email'].isNotEmpty) ...[
                      _buildInfoRow(Icons.email, 'Email', widget.client['email']),
                      const SizedBox(height: 8),
                    ],
                    if (widget.client['phone'].isNotEmpty) ...[
                      _buildInfoRow(Icons.phone, 'Phone', widget.client['phone']),
                      const SizedBox(height: 8),
                    ],
                    if (widget.client['vatNumber'].isNotEmpty)
                      _buildInfoRow(Icons.assignment, 'VAT Number', widget.client['vatNumber']),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.client['contactPerson'].isNotEmpty) ...[
                      _buildInfoRow(Icons.person, 'Contact Person', widget.client['contactPerson']),
                      const SizedBox(height: 8),
                    ],
                    if (widget.client['address'].isNotEmpty)
                      _buildInfoRow(Icons.location_on, 'Address', widget.client['address']),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _buildStatisticsCards(),
            
          const SizedBox(height: 24),
          
          if (widget.client['notes'].isNotEmpty) ...[
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.client['notes']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Projects',
            value: _projectCount.toString(),
            icon: Icons.folder,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Invoices',
            value: _invoiceCount.toString(),
            icon: Icons.receipt,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Invoiced',
            value: '€${_totalInvoiced.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Outstanding',
            value: '€${(_totalInvoiced - _totalPaid).toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Color _withOpacity(Color color, double opacity) {
    return Color.fromRGBO(
      color.r.toInt(), 
      color.g.toInt(), 
      color.b.toInt(), 
      opacity
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _withOpacity(color, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _withOpacity(color, 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .where('clientId', isEqualTo: widget.client['id'])
          .orderBy('createdAt', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final projects = snapshot.data?.docs ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No projects found for this client',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/projects');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index].data() as Map<String, dynamic>;
            final projectId = projects[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: ListTile(
                title: Text(
                  project['title'] ?? 'Untitled Project',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(project['description'] ?? 'No description'),
                trailing: Chip(
                  label: Text(
                    project['status'] ?? 'Active',
                    style: TextStyle(
                      color: _getStatusColor(project['status'] ?? 'Active'),
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: _withOpacity(_getStatusColor(project['status'] ?? 'Active'), 0.1),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/project-detail',
                    arguments: {
                      ...project,
                      'id': projectId,
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Widget _buildInvoicesTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('invoices')
          .where('clientId', isEqualTo: widget.client['id'])
          .orderBy('invoiceDate', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final invoices = snapshot.data?.docs ?? [];

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No invoices found for this client',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/invoices');
                  },
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index].data() as Map<String, dynamic>;
            
            final invoiceDate = (invoice['invoiceDate'] as Timestamp?)?.toDate();
            final formattedDate = invoiceDate != null 
                ? '${invoiceDate.day}/${invoiceDate.month}/${invoiceDate.year}'
                : 'No date';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: ListTile(
                title: Text(
                  invoice['invoiceNumber'] ?? 'Untitled Invoice',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Date: $formattedDate'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '€${(invoice['total'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Chip(
                      label: Text(
                        invoice['status'] ?? 'Draft',
                        style: TextStyle(
                          color: _getInvoiceStatusColor(invoice['status'] ?? 'Draft'),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _withOpacity(_getInvoiceStatusColor(invoice['status'] ?? 'Draft'), 0.1),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/invoices',
                    arguments: {
                      'viewInvoice': true,
                      'invoiceData': invoice,
                      'invoiceId': invoices[index].id,
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getInvoiceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'sent':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
