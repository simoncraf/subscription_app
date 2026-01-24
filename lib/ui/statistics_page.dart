import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../data/settings_store.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';

class _StatsData {
  final List<Subscription> subs;
  final AppSettings settings;
  const _StatsData(this.subs, this.settings);
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _subsStore = SubscriptionStore();
  final _settingsStore = SettingsStore();

  late Future<_StatsData> _future;

  String? _selectedCurrency; // chosen for currency-specific charts

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StatsData> _load() async {
    final results = await Future.wait<dynamic>([
      _subsStore.getAll(),
      _settingsStore.get(),
    ]);

    return _StatsData(
      results[0] as List<Subscription>,
      results[1] as AppSettings,
    );
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(today).inDays;
  }

  // --- Projection helpers ---
  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _addMonths(DateTime d, int months) => DateTime(d.year, d.month + months, 1);

  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  /// Returns next occurrence of a renewal date on/after `from` for monthly recurrence.
  /// We keep it simple: use the day-of-month from the stored renewalDate.
  DateTime _nextMonthlyOccurrence(DateTime renewalDate, DateTime from) {
    final targetDay = renewalDate.day;
    var y = from.year;
    var m = from.month;

    DateTime candidate() {
      // clamp day to last day of month
      final lastDay = DateTime(y, m + 1, 0).day;
      final day = targetDay > lastDay ? lastDay : targetDay;
      return DateTime(y, m, day);
    }

    var c = candidate();
    if (!c.isBefore(DateTime(from.year, from.month, from.day))) return c;

    // move to next month
    final next = DateTime(from.year, from.month + 1, 1);
    y = next.year;
    m = next.month;
    return candidate();
  }

  /// Returns a 6-month projection for a given currency, as a list of (monthStart -> total).
  /// - monthly subscriptions contribute if they renew in that month
  /// - annual subscriptions contribute if their renewalDate month matches
  Map<DateTime, double> _projectNext6Months({
    required List<Subscription> active,
    required String currency,
  }) {
    final now = DateTime.now();
    final start = _startOfMonth(DateTime(now.year, now.month + 1, 1)); // start next month (full month)
    final months = List.generate(6, (i) => _addMonths(start, i));

    final totals = {for (final m in months) m: 0.0};

    for (final s in active.where((x) => x.currency == currency)) {
      final rec = (s.recurrence ?? 'monthly');

      if (rec == 'annual') {
        // include if the stored renewalDate falls in one of the next 6 months
        for (final m in months) {
          if (_isSameMonth(s.renewalDate, m)) {
            totals[m] = (totals[m] ?? 0) + s.price;
          }
        }
      } else {
        // monthly: include if the next occurrence falls in that month
        for (final m in months) {
          final occ = _nextMonthlyOccurrence(s.renewalDate, m);
          if (_isSameMonth(occ, m)) {
            totals[m] = (totals[m] ?? 0) + s.price;
          }
        }
      }
    }

    return totals;
  }

  // --- UI helpers ---
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: FutureBuilder<_StatsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Failed to load statistics.'));
          }

          final subs = data.subs;
          final active = subs.where((s) => !s.isCanceled).toList();
          final canceled = subs.where((s) => s.isCanceled).toList();

          final currencies = <String>{...active.map((s) => s.currency)}.toList()..sort();
          _selectedCurrency ??= currencies.isNotEmpty ? currencies.first : data.settings.defaultCurrency;

          // upcoming renewals (next 30 days) for selected currency
          final selectedCur = _selectedCurrency ?? data.settings.defaultCurrency;
          final upcoming = active
              .where((s) => s.currency == selectedCur)
              .map((s) => _daysUntil(s.renewalDate))
              .where((d) => d >= 0 && d <= 30)
              .toList();

          // bucket by week: 0-6,7-13,14-20,21-30
          final buckets = [0, 0, 0, 0];
          for (final d in upcoming) {
            if (d <= 6) buckets[0]++;
            else if (d <= 13) buckets[1]++;
            else if (d <= 20) buckets[2]++;
            else buckets[3]++;
          }

          final projection = _projectNext6Months(active: active, currency: selectedCur);
          final months = projection.keys.toList()..sort();
          final monthFmt = DateFormat('MMM');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Currency selector
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Currency',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: selectedCur,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: (currencies.isEmpty ? [data.settings.defaultCurrency] : currencies)
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v),
                    ),
                  ),
                ],
              ),

              _sectionTitle('Active vs Canceled'),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: active.length.toDouble(),
                        title: 'Active\n${active.length}',
                        radius: 70,
                      ),
                      PieChartSectionData(
                        value: canceled.length.toDouble(),
                        title: 'Canceled\n${canceled.length}',
                        radius: 70,
                      ),
                    ],
                  ),
                ),
              ),

              _sectionTitle('Upcoming renewals (next 30 days)'),
              SizedBox(
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
                            const labels = ['0–6d', '7–13d', '14–20d', '21–30d'];
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
              ),

              _sectionTitle('Cost projection (next 6 full months)'),
              SizedBox(
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
              ),

              const SizedBox(height: 12),
              Text(
                'Notes:\n'
                '• Charts are shown per currency to avoid mixing values.\n'
                '• Projection assumes your stored renewalDate is the next renewal date.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}