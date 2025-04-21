import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProjectProfitabilityChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  
  const ProjectProfitabilityChart({
    super.key, 
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No project data available for this period'),
      );
    }

    // Take top 10 projects by revenue
    final projects = data.take(10).toList();
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    // Find max values for better scaling
    double maxRevenue = 0;
    double maxHourlyRate = 0;

    for (var project in projects) {
      final revenue = project['revenue'] as double;
      final hourlyRate = project['hourlyRate'] as double;
      
      if (revenue > maxRevenue) maxRevenue = revenue;
      if (hourlyRate > maxHourlyRate) maxHourlyRate = hourlyRate;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.2,
        barGroups: List.generate(projects.length, (index) {
          final project = projects[index];
          final revenue = project['revenue'] as double;
          final hourlyRate = project['hourlyRate'] as double;
          final hours = project['hours'] as double;
          
          // Scale hourly rate to revenue scale for the second bar
          final scaledHourlyRate = hourlyRate * (maxRevenue / maxHourlyRate) * 0.5;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              // Revenue bar
              BarChartRodData(
                toY: revenue,
                color: Colors.indigo,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              // Hourly rate bar
              BarChartRodData(
                toY: scaledHourlyRate,
                color: Colors.orange,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= projects.length) return const Text('');
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      _truncateString(projects[value.toInt()]['name'], 10),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  moneyFormat.format(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 60,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final project = projects[group.x];
              final name = project['name'];
              final hours = project['hours'];
              
              if (rodIndex == 0) {
                return BarTooltipItem(
                  '$name\nRevenue: ${moneyFormat.format(project['revenue'])}\nHours: ${hours.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white),
                );
              } else {
                return BarTooltipItem(
                  '$name\nHourly Rate: ${moneyFormat.format(project['hourlyRate'])}',
                  const TextStyle(color: Colors.white),
                );
              }
            },
          ),
        ),
      ),
    );
  }
  
  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
