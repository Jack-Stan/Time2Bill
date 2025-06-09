import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/web_helper.dart';
import 'package:excel/excel.dart';
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
      if (!mounted) return;
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
      if (!mounted) return;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exportToExcel,
          icon: const Icon(Icons.download),
          label: const Text('Export to Excel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() {
        _isLoading = true;
      });      // Format dates for filename
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final fileName = 'financial_report_${startStr}_to_${endStr}.xlsx';

      // Prepare data for Excel
      final revenueByClient = <String, double>{};
      // hoursByClient can be added later if needed
      final unpaidInvoices = <Map<String, dynamic>>[];
      double totalUnpaidAmount = 0;

      // Get all invoices for the period
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      for (var doc in invoicesSnapshot.docs) {
        final data = doc.data();
        final clientName = data['clientName'] ?? 'Unknown Client';
        final amount = (data['total'] as num?)?.toDouble() ?? 0;
        final status = data['status'] as String? ?? 'unpaid';

        revenueByClient[clientName] = (revenueByClient[clientName] ?? 0) + amount;

        if (status.toLowerCase() != 'paid') {
          unpaidInvoices.add({
            'invoiceNumber': data['invoiceNumber'] ?? 'No number',
            'clientName': clientName,
            'amount': amount,
            'dueDate': data['dueDate'] != null 
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
            'status': status,
          });
          totalUnpaidAmount += amount;
        }
      }

      // Create Excel workbook
      final xlsx = Excel.createExcel();

      // Summary sheet
      final summarySheet = xlsx['Summary'];
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = 'Financial Report'
        ..cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
        );

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        ..value = 'Period';
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        ..value = '$startStr to $endStr';

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        ..value = 'Total Revenue'
        ..cellStyle = CellStyle(bold: true);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        ..value = _totalRevenue;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        ..value = 'Total Hours'
        ..cellStyle = CellStyle(bold: true);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        ..value = _totalHoursBilled;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        ..value = 'Average Rate'
        ..cellStyle = CellStyle(bold: true);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        ..value = _averageHourlyRate;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        ..value = 'Total Unpaid'
        ..cellStyle = CellStyle(bold: true);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        ..value = totalUnpaidAmount;

      // Revenue by client sheet
      final clientSheet = xlsx['Revenue by Client'];
      clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = 'Client'
        ..cellStyle = CellStyle(bold: true);
      clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        ..value = 'Revenue'
        ..cellStyle = CellStyle(bold: true);
      clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        ..value = 'Hours'
        ..cellStyle = CellStyle(bold: true);

      var row = 1;
      for (var entry in _clientRevenueData) {
        clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = entry['name'];
        clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = entry['revenue'];
        clientSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = entry['hours'];
        row++;
      }

      // Unpaid invoices sheet
      final unpaidSheet = xlsx['Unpaid Invoices'];
      unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = 'Invoice Number'
        ..cellStyle = CellStyle(bold: true);
      unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        ..value = 'Client'
        ..cellStyle = CellStyle(bold: true);
      unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        ..value = 'Amount'
        ..cellStyle = CellStyle(bold: true);
      unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
        ..value = 'Due Date'
        ..cellStyle = CellStyle(bold: true);
      unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
        ..value = 'Status'
        ..cellStyle = CellStyle(bold: true);

      row = 1;
      for (var invoice in unpaidInvoices) {
        unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = invoice['invoiceNumber'];
        unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = invoice['clientName'];
        unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = invoice['amount'];
        unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = invoice['dueDate'] != null 
            ? DateFormat('yyyy-MM-dd').format(invoice['dueDate'])
            : 'No due date';
        unpaidSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = invoice['status'];
        row++;
      }      // Convert to bytes and trigger download
      final bytes = xlsx.encode();
      if (bytes != null) {
        WebHelper.downloadFile(bytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
      print('Error exporting to Excel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSummaryCards() {
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    return Row(
      children: [
        // Total Revenue Card
        Expanded(
          child: Tooltip(
            message: 'Total revenue for the selected period',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.euro, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      moneyFormat.format(_totalRevenue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Hours Billed Card
        Expanded(
          child: Tooltip(
            message: 'Total billable hours tracked in this period',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Hours Billed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_totalHoursBilled.toStringAsFixed(1)} hrs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Average Rate Card
        Expanded(
          child: Tooltip(
            message: 'Average hourly rate calculated from revenue and hours',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Average Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${moneyFormat.format(_averageHourlyRate)}/hr',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Active Projects Card  
        Expanded(
          child: Tooltip(
            message: 'Number of projects with tracked time in this period',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Active Projects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activeProjects.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Active Clients Card
        Expanded(
          child: Tooltip(
            message: 'Number of clients with invoices or time entries in this period',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Active Clients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activeClients.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
