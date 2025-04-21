import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/client_form.dart';
import 'widgets/client_details_card.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  int _selectedIndex = 3; // Clients tab index
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _clients = [];
  String _searchQuery = '';
  Map<String, dynamic>? _selectedClient;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
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
          .collection('clients')
          .orderBy('name')
          .get();

      final clients = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Client',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'address': data['address'] ?? '',
          'vatNumber': data['vatNumber'] ?? '',
          'companyName': data['companyName'] ?? '',
          'contactPerson': data['contactPerson'] ?? '',
          'notes': data['notes'] ?? '',
        };
      }).toList();

      // Filter by search query if present
      final filteredClients = _searchQuery.isEmpty 
          ? clients 
          : clients.where((client) {
              final name = client['name'].toString().toLowerCase();
              final company = client['companyName'].toString().toLowerCase();
              final email = client['email'].toString().toLowerCase();
              final lowerQuery = _searchQuery.toLowerCase();
              
              return name.contains(lowerQuery) || 
                     company.contains(lowerQuery) || 
                     email.contains(lowerQuery);
            }).toList();

      setState(() {
        _clients = filteredClients;
        _isLoading = false;
        
        // If we had a selected client, update its data
        if (_selectedClient != null) {
          final updatedClient = filteredClients.firstWhere(
            (client) => client['id'] == _selectedClient!['id'],
            orElse: () => _selectedClient!,
          );
          _selectedClient = updatedClient;
        }
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading clients: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching clients: $error');
    }
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ClientForm(
          onClientSaved: _fetchClients,
        );
      },
    );
  }

  void _showEditClientDialog(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ClientForm(
          client: client,
          onClientSaved: _fetchClients,
        );
      },
    );
  }

  void _showDeleteConfirmation(String clientId, String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete $clientName? This will also delete all projects and invoices associated with this client.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClient(clientId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Delete the client document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .doc(clientId)
          .delete();
      
      // Reset selected client if it was the one deleted
      if (_selectedClient != null && _selectedClient!['id'] == clientId) {
        setState(() {
          _selectedClient = null;
        });
      }
      
      _fetchClients();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting client: $e')),
      );
    }
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
                case 2: // Invoices
                  Navigator.pushReplacementNamed(context, '/invoices');
                  break;
                case 3: // Clients (already on this page)
                  setState(() => _selectedIndex = index);
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
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Client list
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildSearchBar(),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                                  ? _buildErrorView()
                                  : _clients.isEmpty
                                      ? _buildEmptyState()
                                      : _buildClientList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Right side - Client details
                if (_selectedClient != null)
                  Expanded(
                    flex: 4,
                    child: ClientDetailsCard(
                      client: _selectedClient!,
                      onEdit: () => _showEditClientDialog(_selectedClient!),
                      onDelete: () => _showDeleteConfirmation(
                        _selectedClient!['id'],
                        _selectedClient!['name'],
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 4,
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Client Selected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a client from the list to view details',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
          'Clients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddClientDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Client'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search clients...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        _fetchClients();
      },
    );
  }

  Widget _buildClientList() {
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: _clients.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final client = _clients[index];
        final bool isSelected = _selectedClient != null && 
            _selectedClient!['id'] == client['id'];
            
        return ListTile(
          title: Text(
            client['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            client['companyName'] != ''
                ? client['companyName']
                : client['email'],
          ),
          leading: CircleAvatar(
            backgroundColor: isSelected ? primaryColor : Colors.grey[300],
            child: Text(
              client['name'].toString().substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
          selected: isSelected,
          selectedTileColor: primaryColor.withOpacity(0.1),
          onTap: () {
            setState(() {
              _selectedClient = client;
            });
          },
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditClientDialog(client);
              } else if (value == 'delete') {
                _showDeleteConfirmation(
                  client['id'],
                  client['name'],
                );
              }
            },
            itemBuilder: (context) => [
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Clients Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first client to get started',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddClientDialog,
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
            onPressed: _fetchClients,
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
