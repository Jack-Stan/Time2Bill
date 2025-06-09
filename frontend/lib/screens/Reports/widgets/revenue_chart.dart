import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Format numbers and dates
    final moneyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    final dateFormat = DateFormat('dd/MM');

    // Calculate max values for scaling
    double maxRevenue = 0;
    double maxHours = 0;
    for (var point in data) {
      if ((point['revenue'] as double) > maxRevenue) maxRevenue = point['revenue'];
      if ((point['hours'] as double) > maxHours) maxHours = point['hours'];
    }

    // Ensure non-zero max values
    maxRevenue = maxRevenue == 0 ? 1 : maxRevenue;
    maxHours = maxHours == 0 ? 1 : maxHours;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxRevenue / 5,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Convert scaled value back to hours
                final hours = (value / maxRevenue) * maxHours;
                return Text(
                  '${hours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                  ),
                );
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
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final date = DateFormat('yyyy-MM-dd').parse(data[value.toInt()]['date']);
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      dateFormat.format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxRevenue * 1.1, // Add 10% padding at the top
        lineBarsData: [
          // Revenue Line
          LineChartBarData(
            spots: List.generate(data.length, (i) {
              return FlSpot(i.toDouble(), data[i]['revenue']);
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 26), // 0.1 opacity = 26 in 0-255 range
            ),
          ),
          // Hours Line (scaled)
          LineChartBarData(
            spots: List.generate(data.length, (i) {
              // Scale hours to match revenue scale
              final scaledHours = (data[i]['hours'] as double) * (maxRevenue / maxHours);
              return FlSpot(i.toDouble(), scaledHours);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 26), // 0.1 opacity = 26 in 0-255 range
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = DateFormat('yyyy-MM-dd').parse(data[index]['date']);
                if (spot.barIndex == 0) {
                  return LineTooltipItem(
                    '${dateFormat.format(date)}\\n${moneyFormat.format(data[index]['revenue'])}',
                    const TextStyle(color: Colors.green),
                  );
                } else {
                  return LineTooltipItem(
                    '${dateFormat.format(date)}\\n${data[index]['hours'].toStringAsFixed(1)} hours',
                    const TextStyle(color: Colors.blue),
                  );
                }
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
