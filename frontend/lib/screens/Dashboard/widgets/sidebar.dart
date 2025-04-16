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
    final Color primaryColor = const Color(0xFF0B5394);

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Logo and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'lib/utils/images/LogoZonderTitel.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Text(
                  'Time2Bill',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Hoofdnavigatie items
          Expanded(
            child: Column(
              children: [
                // Navigatie menu items bovenaan
                _buildNavItem(context, 'Dashboard', Icons.dashboard, 0, primaryColor),
                _buildNavItem(context, 'Projects', Icons.folder, 6, primaryColor),
                _buildNavItem(context, 'Time Tracking', Icons.timer, 1, primaryColor),
                _buildNavItem(context, 'Invoices', Icons.receipt, 2, primaryColor),
                _buildNavItem(context, 'Clients', Icons.people, 3, primaryColor),
                _buildNavItem(context, 'Reports', Icons.bar_chart, 4, primaryColor),
                
                // Lege ruimte in het midden
                const Spacer(),
              ],
            ),
          ),
          
          // Settings item onderaan (verwijder de Profile knop)
          const Divider(),
          _buildNavItem(context, 'Settings', Icons.settings, 5, primaryColor),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    String title, 
    IconData icon, 
    int index, 
    Color primaryColor,
  ) {
    final isSelected = selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selectedTileColor: Colors.blue.withOpacity(0.1),
      selected: isSelected,
      onTap: () => onItemSelected(index),
    );
  }
}
