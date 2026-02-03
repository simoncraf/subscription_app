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
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    const gap = 10.0;

    return SizedBox(
      height: 260,
      child: Card(
        elevation: 0,
        color: colors.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: gap),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortest = constraints.biggest.shortestSide;
                        final sectionRadius = shortest * 0.34;
                        final centerRadius = shortest * 0.22;

                        return PieChart(
                          key: ValueKey(Object.hash(activeCount, canceledCount)),
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: centerRadius,
                            centerSpaceColor: colors.surface,
                            sections: [
                              PieChartSectionData(
                                value: activeCount.toDouble(),
                                title: '',
                                radius: sectionRadius,
                                color: colors.primary,
                              ),
                              PieChartSectionData(
                                value: canceledCount.toDouble(),
                                title: '',
                                radius: sectionRadius,
                                color: colors.secondary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: colors.primary),
                  const SizedBox(width: 6),
                  Text('Active $activeCount', style: labelStyle),
                  const SizedBox(width: 16),
                  _LegendDot(color: colors.secondary),
                  const SizedBox(width: 6),
                  Text('Canceled $canceledCount', style: labelStyle),
                ],
              ),
              const SizedBox(height: gap),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
