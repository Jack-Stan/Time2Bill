import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/dashboard_overview.dart';
import 'widgets/timer_widget.dart';
import 'widgets/kpi_cards.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF0B5394);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Work Timer
              const Expanded(
                flex: 2,
                child: WorkTimerWidget(),
              ),
              const SizedBox(width: 24),
              // Recent Activity
              Expanded(
                flex: 3,
                child: DashboardOverview(),
              ),
            ],
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
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
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
            const SizedBox(width: 16),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
