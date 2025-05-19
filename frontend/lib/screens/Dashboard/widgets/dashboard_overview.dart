import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../services/firebase_service.dart';
import '../../../services/dashboard_refresh_service.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  DashboardOverviewState createState() => DashboardOverviewState();
}

// Using public state class so it can be accessed with GlobalKey from other files
class DashboardOverviewState extends State<DashboardOverview> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _activities = [];
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<bool>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _fetchRecentActivity();
    // Registreer voor app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Luisteren naar refresh events van de Dashboard service
    final refreshService = DashboardRefreshService();
    _refreshSubscription = refreshService.refreshStream.listen((refresh) {
      if (mounted && refresh) {
        _fetchRecentActivity();
      }
    });
  }

  @override
  void dispose() {
    // Verwijder de observer bij het vernietigen van de widget
    WidgetsBinding.instance.removeObserver(this);
    // Annuleer de subscription
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Wanneer de app weer wordt geopend of naar de voorgrond komt
    if (state == AppLifecycleState.resumed) {
      _fetchRecentActivity();
    }
  }

  // Deze methode wordt openbaar gemaakt zodat deze vanuit de parent aangeroepen kan worden
  void refreshActivity() {
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
      print('Fetching recent time entries for user: ${user.uid}');

      List<Map<String, dynamic>> activities = [];

      try {
        // Alleen tijdregistraties ophalen via de service
        print('Fetching time entries via Firebase Service...');
        // Haal tot 10 entries op zodat we meer recente activiteiten kunnen tonen
        final timeEntries = await _firebaseService.getTimeEntries();
        
        // Neem de eerste 10 tijdregistraties
        if (timeEntries.isNotEmpty) {
          final recentTimeEntries = timeEntries.take(10).map((entry) {
            final dateStr = DateFormat('dd/MM/yyyy').format(entry.startTime);

            // Convert duration (seconds) to hours and minutes
            final durationSeconds = entry.duration.toInt();
            final hours = durationSeconds ~/ 3600;
            final minutes = (durationSeconds % 3600) ~/ 60;
            final durationStr = '${hours}h ${minutes}m';

            // Bepaal de titel en ondertitel
            String title = entry.description;
            String subtitle = entry.projectName != null && entry.projectName!.isNotEmpty 
                ? '${entry.projectName} - $dateStr' 
                : dateStr;

            return {
              'id': entry.id,
              'type': 'time',
              'title': title,
              'subtitle': subtitle,
              'amount': durationStr,
              'icon': Icons.timer,
              'createdAt': Timestamp.fromDate(entry.startTime),
              'projectId': entry.projectId,
              'projectName': entry.projectName,
            };
          }).toList();

          activities.addAll(recentTimeEntries);
          print('✅ Successfully fetched ${recentTimeEntries.length} time entries via service');
        }
      } catch (e) {
        print('❌ Error fetching time entries via service: $e');
        
        // Fallback direct query
        try {
          print('\nFalling back to direct Firestore query for time entries...');
          final timeEntriesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('timeTracking');
          
          final timeEntriesSnapshot = await timeEntriesRef
              .orderBy('createdAt', descending: true)
              .limit(10)  // 10 entries tonen
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

            // Bepaal de titel en ondertitel met projectnaam indien beschikbaar
            final projectName = data['projectName'] as String?;
            String subtitle = projectName != null && projectName.isNotEmpty 
                ? '$projectName - $dateStr' 
                : dateStr;

            return {
              'id': doc.id,
              'type': 'time',
              'title': data['description'] ?? 'Time Entry',
              'subtitle': subtitle,
              'amount': durationStr,
              'icon': Icons.timer,
              'createdAt': timestamp,
              'projectId': data['projectId'],
              'projectName': projectName,
            };
          }).toList();

          activities.addAll(timeEntryActivities);
          print('✅ Successfully fetched ${timeEntryActivities.length} time entries via direct query');
        } catch (e2) {
          print('❌ Error in fallback time entries query: $e2');
        }
      }      // Sort the time entries by creation date
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
        print('\n⚠️ No time entries found.');
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
            padding: const EdgeInsets.all(16),            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Time Entries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigeer naar een dedicated activity page of toon meer activiteiten
                    Navigator.pushNamed(context, '/time-tracking'); // Als tijdelijke oplossing
                  },
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
            )          else if (_activities.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No time entries available yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start tracking time for your projects',
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
                  title: Text(activity['title'] ?? 'Untitled'),                  subtitle: Text(activity['subtitle'] ?? ''),
                  trailing: Text(activity['amount'] ?? ''),                  onTap: () {
                    // Altijd naar time-tracking navigeren met de juiste parameters
                    Navigator.pushNamed(
                      context, 
                      '/time-tracking', 
                      arguments: {'id': activity['id']},
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
