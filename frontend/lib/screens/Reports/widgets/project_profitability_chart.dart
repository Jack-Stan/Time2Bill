import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProjectProfitabilityChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ProjectProfitabilityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    // Sort data by revenue (descending)
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    // Calculate max values for scaling
    double maxRevenue = 0;
    double maxHourlyRate = 0;
    for (var project in sortedData) {
      if (project['revenue'] > maxRevenue) maxRevenue = project['revenue'];
      if (project['hourlyRate'] > maxHourlyRate) maxHourlyRate = project['hourlyRate'];
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final project = sortedData[group.x.toInt()];
              return BarTooltipItem(
                '${project['name']}\\n'
                'Revenue: ${moneyFormat.format(project['revenue'])}\\n'
                'Hours: ${project['hours'].toStringAsFixed(1)}\\n'
                'Rate: ${moneyFormat.format(project['hourlyRate'])}/h',
                const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        sortedData[value.toInt()]['name'],
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  moneyFormat.format(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                // Scale the value back to hours
                final hours = (value / maxRevenue) * maxHourlyRate;
                return Text(
                  '${hours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue / 5,
        ),
        barGroups: List.generate(
          sortedData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sortedData[index]['revenue'],
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
