import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _activities = [];

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

      try {
        // Fetch invoices with proper error handling
        print('\n1. Attempting to fetch invoices...');
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
        print('✅ Successfully fetched ${invoiceActivities.length} invoices');
      } catch (e) {
        print('❌ Error fetching invoices: $e');
        if (e is FirebaseException) {
          print('  Firebase error code: ${e.code}');
          print('  Firebase error message: ${e.message}');
          
          if (e.code == 'failed-precondition' || e.message?.contains('index') == true) {
            print('\n===== INDEX ERROR DETECTED =====');
            print('This error typically occurs when Firestore needs an index for your query.');
            print('FULL ERROR MESSAGE:');
            print(e.toString());
            print('\nLOOK FOR A URL IN THE ABOVE ERROR MESSAGE AND VISIT IT TO CREATE THE INDEX');
            print('===== END INDEX ERROR =====\n');
          }
        }
      }

      try {
        // Fetch time entries
        print('\n2. Attempting to fetch time entries...');
        final timeTrackingRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timeTracking');
        
        final timeEntriesSnapshot = await timeTrackingRef
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        final timeEntries = timeEntriesSnapshot.docs.map((doc) {
          final data = doc.data();
          final timestamp = data['createdAt'] as Timestamp?;
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

        activities.addAll(timeEntries);
        print('✅ Successfully fetched ${timeEntries.length} time entries');
      } catch (e) {
        print('❌ Error fetching time entries: $e');
        if (e is FirebaseException) {
          print('  Firebase error code: ${e.code}');
          print('  Firebase error message: ${e.message}');
          
          if (e.code == 'failed-precondition' || e.message?.contains('index') == true) {
            print('\n===== INDEX ERROR DETECTED =====');
            print('This error typically occurs when Firestore needs an index for your query.');
            print('FULL ERROR MESSAGE:');
            print(e.toString());
            print('\nLOOK FOR A URL IN THE ABOVE ERROR MESSAGE AND VISIT IT TO CREATE THE INDEX');
            print('===== END INDEX ERROR =====\n');
          }
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
      
      final errorMsg = error.toString();
      final urlStartIndex = errorMsg.indexOf('https://console.firebase.google.com');
      if (urlStartIndex != -1) {
        print('\n========== INDEX CREATION URL ==========');
        final url = errorMsg.substring(urlStartIndex);
        print('Copy this URL to create the required index:');
        print(url);
        print('========================================\n');
      }
      
      if (error is FirebaseException) {
        print('\nFirebase Error Details:');
        print('  Code: ${error.code}');
        print('  Message: ${error.message}');
        print('  Stack: ${error.stackTrace}');
        
        if (error.code == 'failed-precondition' && error.message?.contains('index') == true) {
          print('\n⚠️ INDEX ERROR: This query requires an index to be created.');
          print('LOOK FOR THE URL ABOVE TO CREATE THE MISSING INDEX.');
          print('Alternatively, you can update your firestore.indexes.json file and deploy it.');
        }
      }
      
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
