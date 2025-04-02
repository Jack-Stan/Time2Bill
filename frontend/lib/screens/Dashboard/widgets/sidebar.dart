import 'package:flutter/material.dart';

class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'lib/utils/images/LogoMetTitel.jpg',
              height: 50,
            ),
          ),
          const Divider(),
          // Menu Items
          _buildMenuItem(0, 'Dashboard', Icons.dashboard),
          _buildMenuItem(1, 'Time Tracking', Icons.timer),
          _buildMenuItem(2, 'Invoices', Icons.description),
          _buildMenuItem(3, 'Clients', Icons.people),
          _buildMenuItem(4, 'Reports', Icons.bar_chart),
          const Spacer(),
          const Divider(),
          _buildMenuItem(5, 'Settings', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, 
        color: isSelected ? const Color(0xFF0B5394) : Colors.grey,
      ),
      title: Text(title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0B5394) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () => onItemSelected(index),
    );
  }
}
