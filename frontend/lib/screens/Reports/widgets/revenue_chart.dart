import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  
  const RevenueChart({
    super.key, 
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No revenue data available for this period'),
      );
    }

    // Find max values for scaling
    double maxRevenue = 0;
    double maxHours = 0;

    for (var item in data) {
      final revenue = item['revenue'] as double;
      final hours = item['hours'] as double;
      
      if (revenue > maxRevenue) maxRevenue = revenue;
      if (hours > maxHours) maxHours = hours;
    }

    // Format dates for better display
    final dateFormat = DateFormat('dd MMM');
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= data.length) return const Text('');
                
                // Show dates at intervals to avoid overcrowding
                if (data.length > 10) {
                  if (value.toInt() % (data.length ~/ 5) != 0 && 
                      value.toInt() != data.length - 1) {
                    return const Text('');
                  }
                }
                
                final date = DateTime.parse(data[value.toInt()]['date']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dateFormat.format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '€${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Revenue line
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(
                index.toDouble(), 
                (data[index]['revenue'] as double),
              );
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          // Hours line
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              // Scale hours to fit the revenue scale
              final scale = maxRevenue > 0 ? maxRevenue / (maxHours > 0 ? maxHours : 1) : 1;
              return FlSpot(
                index.toDouble(), 
                (data[index]['hours'] as double) * scale,
              );
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < data.length) {
                  final item = data[index];
                  final date = DateTime.parse(item['date']);
                  
                  if (spot.barIndex == 0) {
                    return LineTooltipItem(
                      '${dateFormat.format(date)}\n€${item['revenue'].toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  } else {
                    return LineTooltipItem(
                      '${dateFormat.format(date)}\n${item['hours'].toStringAsFixed(1)} hours',
                      const TextStyle(color: Colors.white),
                    );
                  }
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
