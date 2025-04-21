import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TimeBreakdownChart extends StatelessWidget {
  final Map<String, double> data;
  
  const TimeBreakdownChart({
    super.key, 
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No time tracking data available for this period'),
      );
    }
    
    // Sort data by hours (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    // Take top 5 entries, combine the rest into "Others"
    final int maxSlices = 5;
    double othersValue = 0;
    List<MapEntry<String, double>> chartData = [];
    
    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < maxSlices) {
        chartData.add(sortedEntries[i]);
      } else {
        othersValue += sortedEntries[i].value;
      }
    }
    
    if (othersValue > 0) {
      chartData.add(MapEntry('Others', othersValue));
    }
    
    // Generate pie chart sections
    final sections = chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final Color color = _getColorByIndex(index);
      
      return PieChartSectionData(
        color: color,
        value: data.value,
        title: '${data.value.toStringAsFixed(1)}h',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: chartData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildLegendItem(item.key, _getColorByIndex(index));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _truncateString(title, 15),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getColorByIndex(int index) {
    final colors = [
      const Color(0xFF0B5394),
      const Color(0xFF00A0B0),
      const Color(0xFFEDC951),
      const Color(0xFFCC333F),
      const Color(0xFF6A4A3C),
      const Color(0xFF666666),
    ];
    
    return colors[index % colors.length];
  }
  
  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
