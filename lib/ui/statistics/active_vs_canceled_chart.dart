import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ActiveVsCanceledChart extends StatelessWidget {
  final int activeCount;
  final int canceledCount;

  const ActiveVsCanceledChart({
    super.key,
    required this.activeCount,
    required this.canceledCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              value: activeCount.toDouble(),
              title: 'Active\n$activeCount',
              radius: 70,
            ),
            PieChartSectionData(
              value: canceledCount.toDouble(),
              title: 'Canceled\n$canceledCount',
              radius: 70,
            ),
          ],
        ),
      ),
    );
  }
}
