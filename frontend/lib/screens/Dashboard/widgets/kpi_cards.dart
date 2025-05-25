import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../services/firebase_service.dart';

class KPICardsWidget extends StatefulWidget {
  const KPICardsWidget({super.key});

  @override
  State<KPICardsWidget> createState() => _KPICardsWidgetState();
}

class _KPICardsWidgetState extends State<KPICardsWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  final FirebaseService _firebaseService = FirebaseService();
  
  // KPI data
  double _totalRevenue = 0;
  double _outstandingInvoices = 0;
  double _totalHours = 0;
  int _activeProjects = 0;
  int _totalClients = 0;

  @override
  void initState() {
    super.initState();
    _fetchKPIData();
  }

  Future<void> _fetchKPIData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Gebruik de Firebase service voor betere integratie
      try {
        // 1. Haal alle facturen op
        final invoices = await _firebaseService.getInvoices();
        
        double totalRevenue = 0;
        double outstandingAmount = 0;
        
        for (final invoice in invoices) {
          final total = invoice.total;
          
          totalRevenue += total; // Tel alle facturen mee voor totale omzet
          
          // Tel alleen onbetaalde facturen mee voor openstaand bedrag
          if (invoice.status != 'paid') {
            outstandingAmount += total;
          }
        }
        
        // 2. Haal tijdregistraties op
        final timeEntries = await _firebaseService.getTimeEntries();
        
        double totalHours = 0;
        for (final entry in timeEntries) {
          // Converteer seconden naar uren
          totalHours += entry.duration / 3600;
        }
        
        // 3. Tel actieve projecten (case-insensitive, accepteer ook 'Active', 'active', 'actief', etc.)
        final projects = await _firebaseService.getProjects();
        final activeProjects = projects.where((p) {
          final status = p.status.toLowerCase();
          return status == 'active' || status == 'actief';
        }).length;
        
        // 4. Tel alle klanten
        final clients = await _firebaseService.getClients();
        
        setState(() {
          _totalRevenue = totalRevenue;
          _outstandingInvoices = outstandingAmount;
          _totalHours = totalHours;
          _activeProjects = activeProjects;
          _totalClients = clients.length;
          _isLoading = false;
        });
      } catch (e) {
        print('Error with Firebase service: $e');
        
        // Fallback naar directe Firestore queries
        await _fetchDataWithDirectQueries(user.uid);
      }
    } catch (error) {
      print('Failed to fetch KPI data: $error');
      setState(() {
        _errorMessage = 'Error loading KPI data: ${error.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchDataWithDirectQueries(String userId) async {
    // 1. Haal factuurgegevens op
    final invoicesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .get();
    
    double totalRevenue = 0;
    double outstandingAmount = 0;
    
    for (final doc in invoicesSnapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String? ?? '';
      
      totalRevenue += total;
      
      if (status != 'paid') {
        outstandingAmount += total;
      }
    }
    
    // 2. Haal tijdsregistraties op
    final timeEntriesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('timeTracking')
        .get();
    
    double totalHours = 0;
    for (final doc in timeEntriesSnapshot.docs) {
      final data = doc.data();
      final duration = (data['duration'] as num?)?.toDouble() ?? 0;
      totalHours += duration / 3600; // seconden naar uren
    }
    
    // 3. Haal projecten op
    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('projects')
        .get();
    
    int activeProjects = 0;
    for (final doc in projectsSnapshot.docs) {
      final data = doc.data();
      final status = (data['status'] as String? ?? '').toLowerCase();
      if (status == 'active' || status == 'actief') {
        activeProjects++;
      }
    }
    
    // 4. Haal klanten op
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('clients')
        .get();
    
    setState(() {
      _totalRevenue = totalRevenue;
      _outstandingInvoices = outstandingAmount;
      _totalHours = totalHours;
      _activeProjects = activeProjects;
      _totalClients = clientsSnapshot.docs.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    if (_isLoading) {
      return SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(height: 8),
              Text('Error loading KPI data'),
              TextButton.icon(
                onPressed: _fetchKPIData,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Row(
      children: [
        // Revenue
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.euro, color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Text('Total Revenue', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    moneyFormat.format(_totalRevenue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        
        // Outstanding Invoices
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Text('Outstanding', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    moneyFormat.format(_outstandingInvoices),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        
        // Total Hours
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Text('Total Hours', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _totalHours.toStringAsFixed(1) + ' h',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        
        // Active Projects
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder, color: Colors.purple[700], size: 20),
                      SizedBox(width: 8),
                      Text('Active Projects', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _activeProjects.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        
        // Total Clients
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.teal[700], size: 20),
                      SizedBox(width: 8),
                      Text('Clients', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _totalClients.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
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
}
