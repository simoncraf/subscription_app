import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CostProjectionChart extends StatelessWidget {
  final Map<DateTime, double> projection;

  const CostProjectionChart({
    super.key,
    required this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final months = projection.keys.toList()..sort();
    final monthFmt = DateFormat('MMM');

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(monthFmt.format(months[i]), style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),
          minX: 0,
          maxX: (months.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
              spots: List.generate(months.length, (i) {
                final m = months[i];
                return FlSpot(i.toDouble(), (projection[m] ?? 0).toDouble());
              }),
            ),
          ],
        ),
      ),
    );
  }
}
