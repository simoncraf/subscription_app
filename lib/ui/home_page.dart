import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/subscription.dart';
import '../data/subscription_store.dart';
import '../data/settings_store.dart';
import 'add_subscription_sheet.dart';
import 'home/active_subscriptions_section.dart';
import 'home/canceled_subscriptions_section.dart';
import 'home/home_data.dart';
import 'home/home_helpers.dart';
import 'home/totals_card.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'subscription_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = SubscriptionStore();
  final _settingsStore = SettingsStore();

  late Future<HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<HomeData> _loadData() async {
    final results = await Future.wait<dynamic>([
      _store.getAllNormalized(),
      _settingsStore.get(),
    ]);

    return HomeData(
      results[0] as List<Subscription>,
      results[1] as AppSettings,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddSubscriptionSheet(),
    );

    if (created == true) {
      await _refresh();
    }
  }

  Future<bool> _confirmCancel(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: Text(
          'Cancel "$name"?\n\nIt will be moved to History (not deleted).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            await _refresh();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsPage()),
              );
              await _refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Failed to load data.'));
          }

          final subs = data.subs;
          final st = data.settings;

          if (subs.isEmpty) {
            return const Center(
              child: Text(
                'No subscriptions yet.\nTap + to add one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final active = subs.where((s) => !s.isCanceled).toList();
          final canceled = subs.where((s) => s.isCanceled).toList();

          final totalsMode = st.homeTotalMode; // 'monthly' or 'annual'
          final monthlyView = st.monthlyTotalView; // 'next' or 'current'

          final Map<String, double> totals = (totalsMode == 'annual')
              ? calculateAnnualTotals(active)
              : (monthlyView == 'current'
                  ? calculateCurrentMonthRemainingTotals(active)
                  : calculateNextMonthTotals(active));

          final currencies = activeCurrencies(active);

          active.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
          canceled.sort((a, b) {
            final at = a.canceledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.canceledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });

          final df = DateFormat('yyyy-MM-dd');
          final titleText = (totalsMode == 'annual')
              ? 'Total ANNUAL'
              : (st.monthlyTotalView == 'current'
                  ? 'Total - ${currentMonthLabel()} (REMAINING)'
                  : 'Total - ${nextMonthLabel()}');

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TotalsCard(
                titleText: titleText,
                totals: totals,
                currencies: currencies,
                settings: st,
              ),
              const SizedBox(height: 12),
              ActiveSubscriptionsSection(
                active: active,
                settings: st,
                dateFormat: df,
                onConfirmCancel: _confirmCancel,
                onCancel: (s) async {
                  await _store.cancel(s.id);
                  await _refresh();
                },
                onOpenDetails: (s) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionDetailsPage(
                        subscriptionId: s.id,
                      ),
                    ),
                  );
                  await _refresh();
                },
              ),
              const SizedBox(height: 16),
              CanceledSubscriptionsSection(
                canceled: canceled,
                dateFormat: df,
                onOpenDetails: (s) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionDetailsPage(
                        subscriptionId: s.id,
                      ),
                    ),
                  );
                  await _refresh();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
