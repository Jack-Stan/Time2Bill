import 'package:flutter/material.dart';

class KPICardsWidget extends StatelessWidget {
  const KPICardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      children: const [
        KPICard(
          title: 'Total Hours',
          value: '164.5',
          unit: 'hours',
          icon: Icons.timer,
          color: Color(0xFF0B5394),
        ),
        KPICard(
          title: 'Outstanding',
          value: '€4,250',
          unit: 'EUR',
          icon: Icons.account_balance_wallet,
          color: Color(0xFFE65100),
        ),
        KPICard(
          title: 'Monthly Revenue',
          value: '€12,480',
          unit: 'EUR',
          icon: Icons.trending_up,
          color: Color(0xFF2E7D32),
        ),
        KPICard(
          title: 'Active Projects',
          value: '8',
          unit: 'projects',
          icon: Icons.work,
          color: Color(0xFF6200EA),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
