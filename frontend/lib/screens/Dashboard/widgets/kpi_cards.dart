import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KPICardsWidget extends StatefulWidget {
  const KPICardsWidget({super.key});

  @override
  State<KPICardsWidget> createState() => _KPICardsWidgetState();
}

class _KPICardsWidgetState extends State<KPICardsWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _dataAvailable = false;
  Map<String, dynamic> _kpiData = {
    'totalHours': '0',
    'outstanding': '€0',
    'monthlyRevenue': '€0',
    'activeProjects': '0',
  };

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

      // Fetch active projects count
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .where('status', isEqualTo: 'Active')
          .get();
      
      final activeProjectsCount = projectsSnapshot.docs.length;

      // Fetch outstanding invoices amount
      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('status', isEqualTo: 'unpaid')
          .get();
      
      double outstandingAmount = 0;
      for (final doc in invoicesSnapshot.docs) {
        final amount = doc.data()['total'];
        if (amount is num) {
          outstandingAmount += amount.toDouble();
        }
      }

      // Fetch this month's revenue
      final DateTime now = DateTime.now();
      final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      final revenueSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('status', isEqualTo: 'paid')
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();
      
      double monthlyRevenue = 0;
      for (final doc in revenueSnapshot.docs) {
        final amount = doc.data()['total'];
        if (amount is num) {
          monthlyRevenue += amount.toDouble();
        }
      }

      // Fetch total hours
      final timeTrackingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timeTracking')
          .get();
      
      double totalHours = 0;
      for (final doc in timeTrackingSnapshot.docs) {
        final duration = doc.data()['duration'];
        if (duration is num) {
          totalHours += duration / 3600; // Convert seconds to hours
        }
      }

      setState(() {
        _kpiData = {
          'totalHours': totalHours.toStringAsFixed(1),
          'outstanding': outstandingAmount > 0 ? '€${outstandingAmount.toStringAsFixed(0)}' : '-',
          'monthlyRevenue': monthlyRevenue > 0 ? '€${monthlyRevenue.toStringAsFixed(0)}' : '-',
          'activeProjects': activeProjectsCount > 0 ? activeProjectsCount.toString() : '-',
        };
        _isLoading = false;
        _dataAvailable = activeProjectsCount > 0 || 
                         outstandingAmount > 0 || 
                         monthlyRevenue > 0 || 
                         totalHours > 0;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
      print('Error fetching KPI data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('Error loading data: $_errorMessage'),
              TextButton.icon(
                onPressed: _fetchKPIData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_dataAvailable) {
      return SizedBox(
        height: 120,
        child: Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart, size: 32, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No metrics available yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start tracking time and creating invoices to see your KPIs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 250.0;
        final crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 4);
        
        return SizedBox(
          height: 110,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
              mainAxisExtent: 100,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return KPICard(
                    title: 'Total Hours',
                    value: _kpiData['totalHours'],
                    unit: 'hours',
                    icon: Icons.timer,
                    color: const Color(0xFF0B5394),
                  );
                case 1:
                  return KPICard(
                    title: 'Outstanding',
                    value: _kpiData['outstanding'],
                    unit: 'EUR',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFFE65100),
                  );
                case 2:
                  return KPICard(
                    title: 'Monthly Revenue',
                    value: _kpiData['monthlyRevenue'],
                    unit: 'EUR',
                    icon: Icons.trending_up,
                    color: const Color(0xFF2E7D32),
                  );
                case 3:
                default:
                  return KPICard(
                    title: 'Active Projects',
                    value: _kpiData['activeProjects'],
                    unit: 'projects',
                    icon: Icons.work,
                    color: const Color(0xFF6200EA),
                  );
              }
            },
          ),
        );
      }
    );
  }
}

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
