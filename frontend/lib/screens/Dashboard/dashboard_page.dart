import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/dashboard_overview.dart';
import 'widgets/timer_widget.dart';
import 'widgets/kpi_cards.dart';
import '../../services/firebase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF0B5394);  // Key om naar het dashboard overview te verwijzen
  final _dashboardOverviewKey = GlobalKey<DashboardOverviewState>();

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
                  // Already on Dashboard, just update the selected index
                  setState(() => _selectedIndex = index);
                  break;
                case 1: // Time Tracking
                  Navigator.pushNamed(context, '/time-tracking');
                  break;
                case 2: // Invoices
                  Navigator.pushNamed(context, '/invoices');
                  break;
                case 3: // Clients
                  Navigator.pushNamed(context, '/clients');
                  break;
                case 4: // Reports
                  Navigator.pushNamed(context, '/reports');
                  break;
                case 5: // Settings
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 6: // Projects
                  Navigator.pushNamed(context, '/projects');
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
          // Header with user info and quick actions
          _buildHeader(),
          const SizedBox(height: 24),
          // KPI Cards
          const KPICardsWidget(),
          const SizedBox(height: 24),
          // Timer and Recent Activity
          LayoutBuilder(builder: (context, constraints) {
            return constraints.maxWidth < 900
                ? Column(
                    children: [
                      // Work Timer
                      const WorkTimerWidget(),
                      const SizedBox(height: 24),                      // Recent Activity
                      DashboardOverview(key: _dashboardOverviewKey),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Work Timer
                      const Expanded(
                        flex: 2,
                        child: WorkTimerWidget(),
                      ),
                      const SizedBox(width: 24),                      // Recent Activity
                      Expanded(
                        flex: 3,
                        child: DashboardOverview(key: _dashboardOverviewKey),
                      ),
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Debug: Test Firestore permissions
              Flexible(
                child: ElevatedButton(
                  onPressed: () async {
                    final firebaseService = FirebaseService();
                    final results = await firebaseService.testFirestorePermissions();
                    
                    if (!mounted) return;
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Firebase Permissions Test'),
                        content: SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: results.entries.map((entry) => 
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text('${entry.key}: ', 
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      entry.value 
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.cancel, color: Colors.red),
                                    ],
                                  ),
                                )
                              ).toList(),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Permissions'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement new invoice action
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Make the profile icon clickable
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
