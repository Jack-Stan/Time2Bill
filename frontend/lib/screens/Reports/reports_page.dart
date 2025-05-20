import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/time_breakdown_chart.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/project_profitability_chart.dart';
import 'widgets/client_revenue_chart.dart';
import 'widgets/date_range_selector.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedIndex = 4; // Reports tab index
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  String? _errorMessage;

  // Date range for filtering
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Report data
  Map<String, double> _projectTimeData = {};
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _projectProfitabilityData = [];
  List<Map<String, dynamic>> _clientRevenueData = [];
  
  // Summary statistics
  double _totalRevenue = 0;
  double _totalHoursBilled = 0;
  double _averageHourlyRate = 0;
  int _activeProjects = 0;
  int _activeClients = 0;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  void _updateDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Convert dates to timestamps for Firestore queries
      final startTimestamp = Timestamp.fromDate(_startDate);
      final endTimestamp = Timestamp.fromDate(_endDate);

      // Initialize data structures
      Map<String, double> projectTimeData = {};
      Map<String, double> clientTimeData = {};
      List<Map<String, dynamic>> revenueData = [];
      Map<String, double> projectTotalTime = {};
      Map<String, double> projectTotalRevenue = {};
      Map<String, double> clientTotalRevenue = {};
      
      // 1. Fetch time tracking data
      final timeTrackingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timeTracking')
          .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('startTime', isLessThanOrEqualTo: endTimestamp)
          .get();

      // Process time tracking data
      for (var doc in timeTrackingSnapshot.docs) {
        final data = doc.data();
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        final hours = duration / 3600; // Convert seconds to hours
        final projectId = data['projectId'] as String? ?? 'Unassigned';
        final clientId = data['clientId'] as String? ?? 'Unassigned';
        
        // Aggregate time by project
        projectTimeData[projectId] = (projectTimeData[projectId] ?? 0) + hours;
        projectTotalTime[projectId] = (projectTotalTime[projectId] ?? 0) + hours;
        
        // Aggregate time by client
        clientTimeData[clientId] = (clientTimeData[clientId] ?? 0) + hours;
        
        // Add to revenue data (for time series)
        final date = (data['startTime'] as Timestamp).toDate();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        // Update or add to revenue data
        bool found = false;
        for (var entry in revenueData) {
          if (entry['date'] == dateStr) {
            entry['hours'] = (entry['hours'] as double) + hours;
            found = true;
            break;
          }
        }
        
        if (!found) {
          revenueData.add({
            'date': dateStr,
            'hours': hours,
            'revenue': 0.0,
          });
        }
      }

      // 2. Fetch invoice data
      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('invoiceDate', isGreaterThanOrEqualTo: startTimestamp)
          .where('invoiceDate', isLessThanOrEqualTo: endTimestamp)
          .get();
      
      // Process invoice data
      for (var doc in invoicesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total'] as num?)?.toDouble() ?? 0;
        final clientId = data['clientId'] as String? ?? 'Unassigned';
        final date = (data['invoiceDate'] as Timestamp).toDate();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final projectId = data['projectId'] as String? ?? 'Unassigned';
        
        // Aggregate revenue by project
        projectTotalRevenue[projectId] = (projectTotalRevenue[projectId] ?? 0) + amount;
        
        // Aggregate revenue by client
        clientTotalRevenue[clientId] = (clientTotalRevenue[clientId] ?? 0) + amount;
        
        // Update or add to revenue data
        bool found = false;
        for (var entry in revenueData) {
          if (entry['date'] == dateStr) {
            entry['revenue'] = (entry['revenue'] as double) + amount;
            found = true;
            break;
          }
        }
        
        if (!found) {
          revenueData.add({
            'date': dateStr,
            'hours': 0.0,
            'revenue': amount,
          });
        }
      }

      // Sort revenue data by date
      revenueData.sort((a, b) => a['date'].compareTo(b['date']));
      
      // 3. Calculate project profitability
      List<Map<String, dynamic>> projectProfitabilityData = [];
      
      // Fetch project names
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .get();
          
      final projectNames = {
        for (var doc in projectsSnapshot.docs) 
          doc.id: (doc.data()['title'] as String?) ?? 'Unnamed Project'
      };
      
      // Add 'Unassigned' project
      projectNames['Unassigned'] = 'Unassigned';
      
      // Create project profitability data
      for (var projectId in {...projectTotalTime.keys, ...projectTotalRevenue.keys}) {
        final time = projectTotalTime[projectId] ?? 0;
        final revenue = projectTotalRevenue[projectId] ?? 0;
        final hourlyRate = time > 0 ? revenue / time : 0;
        
        projectProfitabilityData.add({
          'id': projectId,
          'name': projectNames[projectId] ?? 'Unknown Project',
          'hours': time,
          'revenue': revenue,
          'hourlyRate': hourlyRate,
        });
      }
      
      // Sort by revenue (descending)
      projectProfitabilityData.sort((a, b) => 
          (b['revenue'] as double).compareTo(a['revenue'] as double));
          
      // 4. Calculate client revenue data  
      List<Map<String, dynamic>> clientRevenueData = [];
      
      // Fetch client names
      final clientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .get();
          
      final clientNames = {
        for (var doc in clientsSnapshot.docs) 
          doc.id: (doc.data()['name'] as String?) ?? 'Unnamed Client'
      };
      
      // Add 'Unassigned' client
      clientNames['Unassigned'] = 'Unassigned';
      
      // Create client revenue data
      for (var clientId in {...clientTimeData.keys, ...clientTotalRevenue.keys}) {
        final time = clientTimeData[clientId] ?? 0;
        final revenue = clientTotalRevenue[clientId] ?? 0;
        
        clientRevenueData.add({
          'id': clientId,
          'name': clientNames[clientId] ?? 'Unknown Client',
          'hours': time,
          'revenue': revenue,
        });
      }
      
      // Sort by revenue (descending)
      clientRevenueData.sort((a, b) => 
          (b['revenue'] as double).compareTo(a['revenue'] as double));
      
      // 5. Calculate summary statistics
      double totalRevenue = 0;
      double totalHours = 0;
      
      for (var entry in revenueData) {
        totalRevenue += entry['revenue'] as double;
        totalHours += entry['hours'] as double;
      }
      
      final averageHourlyRate = totalHours > 0 ? totalRevenue / totalHours : 0;
      final activeProjects = projectTimeData.length;
      final activeClients = clientTimeData.length;

      // Update state with all the data
      setState(() {
        _projectTimeData = projectTimeData;
        _revenueData = revenueData;
        _projectProfitabilityData = projectProfitabilityData;
        _clientRevenueData = clientRevenueData;
        _totalRevenue = totalRevenue;
        _totalHoursBilled = totalHours;
        _averageHourlyRate = averageHourlyRate.toDouble();
        _activeProjects = activeProjects;
        _activeClients = activeClients;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading report data: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching report data: $error');
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
                case 3: // Clients
                  Navigator.pushReplacementNamed(context, '/clients');
                  break;
                case 4: // Reports (already on this page)
                  setState(() => _selectedIndex = index);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          DateRangeSelector(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _updateDateRange,
          ),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorView()
          else
            _buildReportCharts(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Revenue', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
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
        const SizedBox(width: 16),
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
                      const SizedBox(width: 8),
                      const Text('Hours Billed', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalHoursBilled.toStringAsFixed(1) + ' h',
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
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.euro, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Average Rate', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moneyFormat.format(_averageHourlyRate) + '/h',
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
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Active Clients', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeClients.toString(),
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
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder, color: Colors.teal[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Active Projects', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeProjects.toString(),
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

  Widget _buildReportCharts() {
    return Column(
      children: [
        // First row of charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Over Time Chart
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue & Hours Over Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: RevenueChart(data: _revenueData),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Time Breakdown Chart
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Breakdown by Project',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: TimeBreakdownChart(data: _projectTimeData),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Second row of charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Profitability Chart
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Profitability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: ProjectProfitabilityChart(data: _projectProfitabilityData),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Client Revenue Chart
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue by Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: ClientRevenueChart(data: _clientRevenueData),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
            onPressed: _fetchReportData,
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
