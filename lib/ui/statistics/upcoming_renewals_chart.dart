import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UpcomingRenewalsChart extends StatelessWidget {
  final List<int> buckets;

  const UpcomingRenewalsChart({
    super.key,
    required this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                                    const labels = ['0-6d', '7-13d', '14-20d', '21-30d'];
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[idx], style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(4, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
