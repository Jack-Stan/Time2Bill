import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/firebase_service.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _activities = [];
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _fetchRecentActivity();
  }

  Future<void> _fetchRecentActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('===== FETCHING DASHBOARD ACTIVITY =====');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('Fetching activity for user: ${user.uid}');

      List<Map<String, dynamic>> activities = [];

      // Een betere aanpak: gebruik de FirebaseService
      try {
        // Fetch invoices using the service
        print('\n1. Fetching most recent invoices via Firebase Service...');
        final invoices = await _firebaseService.getInvoices();
        
        // Neem alleen de eerste 5 facturen
        final recentInvoices = invoices.take(5).map((invoice) {
          final dateStr = invoice.invoiceDate != null
              ? DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)
              : 'Unknown date';

          return {
            'id': invoice.id,
            'type': 'invoice',
            'title': invoice.invoiceNumber,
            'subtitle': 'Created on $dateStr',
            'amount': '€${invoice.total.toStringAsFixed(2)}',
            'icon': Icons.description,
            'createdAt': Timestamp.fromDate(invoice.invoiceDate),
          };
        }).toList();

        activities.addAll(recentInvoices);
        print('✅ Successfully fetched ${recentInvoices.length} invoices via service');
      } catch (e) {
        print('❌ Error fetching invoices via service: $e');
        
        // Fallback naar de directe Firestore aanpak indien de service faalt
        try {
          print('\n1b. Falling back to direct Firestore query for invoices...');
          final invoicesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('invoices');
          
          final invoicesSnapshot = await invoicesRef
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

          final invoiceActivities = invoicesSnapshot.docs.map((doc) {
            final data = doc.data();
            final timestamp = data['createdAt'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
                : 'Unknown date';

            return {
              'id': doc.id,
              'type': 'invoice',
              'title': data['invoiceNumber'] ?? 'Invoice',
              'subtitle': 'Created on $dateStr',
              'amount': data['total'] != null ? '€${data['total']}' : '',
              'icon': Icons.description,
              'createdAt': timestamp,
            };
          }).toList();

          activities.addAll(invoiceActivities);
          print('✅ Successfully fetched ${invoiceActivities.length} invoices via direct query');
        } catch (e2) {
          print('❌ Error in fallback invoice query: $e2');
        }
      }

      try {
        // Fetch time entries using the service
        print('\n2. Fetching time entries via Firebase Service...');
        final timeEntries = await _firebaseService.getTimeEntries();
        
        // Neem alleen de eerste 5 tijdregistraties
        final recentTimeEntries = timeEntries.take(5).map((entry) {
          final dateStr = entry.startTime != null
              ? DateFormat('dd/MM/yyyy').format(entry.startTime)
              : 'Unknown date';

          // Convert duration (seconds) to hours and minutes
          final durationSeconds = entry.duration.toInt();
          final hours = durationSeconds ~/ 3600;
          final minutes = (durationSeconds % 3600) ~/ 60;
          final durationStr = '${hours}h ${minutes}m';

          return {
            'id': entry.id,
            'type': 'time',
            'title': entry.description,
            'subtitle': dateStr,
            'amount': durationStr,
            'icon': Icons.timer,
            'createdAt': Timestamp.fromDate(entry.startTime),
          };
        }).toList();

        activities.addAll(recentTimeEntries);
        print('✅ Successfully fetched ${recentTimeEntries.length} time entries via service');
      } catch (e) {
        print('❌ Error fetching time entries via service: $e');
        
        // Fallback direct query
        try {
          print('\n2b. Falling back to direct Firestore query for time entries...');
          final timeEntriesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('timeTracking');
          
          final timeEntriesSnapshot = await timeEntriesRef
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

          final timeEntryActivities = timeEntriesSnapshot.docs.map((doc) {
            final data = doc.data();
            final timestamp = data['startTime'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
                : 'Unknown date';

            // Convert duration (seconds) to hours and minutes
            final durationSeconds = (data['duration'] as num?)?.toInt() ?? 0;
            final hours = durationSeconds ~/ 3600;
            final minutes = (durationSeconds % 3600) ~/ 60;
            final durationStr = '${hours}h ${minutes}m';

            return {
              'id': doc.id,
              'type': 'time',
              'title': data['description'] ?? 'Time Entry',
              'subtitle': dateStr,
              'amount': durationStr,
              'icon': Icons.timer,
              'createdAt': timestamp,
            };
          }).toList();

          activities.addAll(timeEntryActivities);
          print('✅ Successfully fetched ${timeEntryActivities.length} time entries via direct query');
        } catch (e2) {
          print('❌ Error in fallback time entries query: $e2');
        }
      }

      // Create a combined, sorted list using createdAt timestamps
      if (activities.isNotEmpty) {
        activities.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1; // null comes last
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime); // descending order (newest first)
        });
      } else {
        print('\n⚠️ No activities found.');
      }

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading activity data: ${error.toString()}';
        _isLoading = false;
      });

      print('\n===== DASHBOARD ACTIVITY ERROR =====');
      print('Error type: ${error.runtimeType}');
      print('Error message: $error');
      print('===== END ERROR =====\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: $_errorMessage'),
                    TextButton.icon(
                      onPressed: _fetchRecentActivity,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_activities.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No activity data available yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start tracking time or creating invoices',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    child: Icon(
                      activity['icon'] ?? Icons.info,
                      color: const Color(0xFF0B5394),
                    ),
                  ),
                  title: Text(activity['title'] ?? 'Untitled'),
                  subtitle: Text(activity['subtitle'] ?? ''),
                  trailing: Text(activity['amount'] ?? ''),
                );
              },
            ),
        ],
      ),
    );
  }
}
