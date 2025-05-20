import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ClientRevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  
  const ClientRevenueChart({
    super.key, 
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No client data available for this period'),
      );
    }

    // Take top 10 clients by revenue
    final clients = data.take(10).toList();
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: clients.isNotEmpty ? (clients[0]['revenue'] as double) * 1.2 : 100,
        barGroups: List.generate(clients.length, (index) {
          final client = clients[index];
          final revenue = client['revenue'] as double;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: revenue,
                color: Colors.teal,
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
                if (value < 0 || value >= clients.length) return const Text('');
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      _truncateString(clients[value.toInt()]['name'], 10),
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
            tooltipBgColor: Color.fromRGBO(Colors.blueGrey.r.toInt(), Colors.blueGrey.g.toInt(), Colors.blueGrey.b.toInt(), 0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final client = clients[group.x];
              final name = client['name'];
              final revenue = client['revenue'] as double;
              final hours = client['hours'] as double;
              
              return BarTooltipItem(
                '$name\nRevenue: ${moneyFormat.format(revenue)}\nHours: ${hours.toStringAsFixed(1)}',
                const TextStyle(color: Colors.white),
              );
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
