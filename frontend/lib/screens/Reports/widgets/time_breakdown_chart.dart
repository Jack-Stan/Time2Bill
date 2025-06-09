import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TimeBreakdownChart extends StatelessWidget {
  final Map<String, double> data;

  const TimeBreakdownChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Convert data to list and sort by hours (descending)
    final items = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total hours
    final totalHours = items.fold<double>(0, (sum, item) => sum + item.value);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: items.map((entry) {
                final percent = (entry.value / totalHours * 100);
                final color = Colors.primaries[items.indexOf(entry) % Colors.primaries.length];
                
                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: '${percent.toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...items.map((entry) {
                final color = Colors.primaries[items.indexOf(entry) % Colors.primaries.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.value.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
