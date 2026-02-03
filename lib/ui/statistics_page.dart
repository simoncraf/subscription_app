import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';
import 'statistics/active_vs_canceled_chart.dart';
import 'statistics/currency_selector_row.dart';
import 'statistics/monthly_expenses_chart.dart';
import 'statistics/section_title.dart';
import 'statistics/statistics_notes.dart';
import 'statistics/stats_data.dart';
import 'statistics/stats_helpers.dart';
import 'statistics/upcoming_renewals_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _subsStore = SubscriptionStore();
  final _settingsStore = SettingsStore();

  late Future<StatsData> _future;

  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StatsData> _load() async {
    final results = await Future.wait<dynamic>([
      _subsStore.getAllNormalized(),
      _settingsStore.get(),
    ]);

    return StatsData(
      results[0] as List<Subscription>,
      results[1] as AppSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: FutureBuilder<StatsData>(
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

          final currencies = <String>{...active.map((s) => s.currency)}.toList()
            ..sort();
          _selectedCurrency ??=
              currencies.isNotEmpty ? currencies.first : data.settings.defaultCurrency;

          final selectedCur = _selectedCurrency ?? data.settings.defaultCurrency;
          final buckets = buildUpcomingBuckets(active: active, currency: selectedCur);
          final monthlyExpenses = projectCurrentAndNext3Months(
            active: active,
            currency: selectedCur,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CurrencySelectorRow(
                currencies: currencies.isEmpty
                    ? [data.settings.defaultCurrency]
                    : currencies,
                selected: selectedCur,
                onChanged: (v) => setState(() => _selectedCurrency = v),
              ),
              const SectionTitle(
                text: 'Monthly expenses',
              ),
              MonthlyExpensesChart(totals: monthlyExpenses),
              const SectionTitle(text: 'Upcoming renewals'),
              UpcomingRenewalsChart(buckets: buckets),
              const SectionTitle(text: 'Active vs Canceled'),
              ActiveVsCanceledChart(
                activeCount: active.length,
                canceledCount: canceled.length,
              ),
              const SizedBox(height: 12),
              const StatisticsNotes(),
            ],
          );
        },
      ),
    );
  }
}
