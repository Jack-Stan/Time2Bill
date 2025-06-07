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
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to refresh events from the Dashboard service
    // Initialize dashboard refresh service
    final refreshService = DashboardRefreshService();
    _refreshSubscription = refreshService.refreshStream.listen((refresh) {
      if (mounted && refresh) {
        _fetchRecentActivity();
      }
    }, onError: (error) {
      // Handle stream errors silently
    }, cancelOnError: false);
  }
  @override
  void dispose() {
    // Cancel all subscriptions and cleanup resources
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
    
    // Remove the lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only refresh if the widget is still mounted and app is resumed
    if (mounted && state == AppLifecycleState.resumed) {
      _fetchRecentActivity();
    }
  }

  // Deze methode wordt openbaar gemaakt zodat deze vanuit de parent aangeroepen kan worden
  void refreshActivity() {
    _fetchRecentActivity();
  }
  Future<void> _fetchRecentActivity() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      List<Map<String, dynamic>> activities = [];
      Map<String, double> projectTimeTotals = {};

      // Haal tijdregistraties op
      final timeEntries = await _firebaseService.getTimeEntries();

      // 1. Tijdregistraties verwerken
      if (timeEntries.isNotEmpty) {
        final recentTimeEntries = timeEntries.take(10).map((entry) {
          final dateStr = DateFormat('dd/MM/yyyy').format(entry.startTime);
          final durationSeconds = entry.duration.toInt();
          final hours = durationSeconds ~/ 3600;
          final minutes = (durationSeconds % 3600) ~/ 60;
          final durationStr = '${hours}h ${minutes}m';

          // Toon taaknaam als die er is
          String title = entry.taskTitle != null && entry.taskTitle!.isNotEmpty
              ? '${entry.taskTitle}: ${entry.description}'
              : entry.description;
          String subtitle = entry.projectName != null && entry.projectName!.isNotEmpty
              ? '${entry.projectName} - ${dateStr}'
              : dateStr;

          // Totaal per project optellen
          if (entry.projectId != null) {
            projectTimeTotals[entry.projectId!] = (projectTimeTotals[entry.projectId!] ?? 0) + entry.duration;
          }

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
      }

      // Sort time entries by creation date
      if (activities.isNotEmpty) {
        activities.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      }

            if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading activity data: ${error.toString()}';
          _isLoading = false;
        });
      }
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
                  title: Text(activity['title'] ?? 'Untitled'),
                  subtitle: Text(activity['subtitle'] ?? ''),
                  trailing: Text(activity['amount'] ?? ''),
                  onTap: () {
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
