import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/subscription.dart';
import '../data/subscription_store.dart';
import '../data/settings_store.dart';
import 'add_subscription_sheet.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'subscription_details_page.dart';

class _HomeData {
  final List<Subscription> subs;
  final AppSettings settings;

  const _HomeData(this.subs, this.settings);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = SubscriptionStore();
  final _settingsStore = SettingsStore();

  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_HomeData> _loadData() async {
    final results = await Future.wait<dynamic>([
      _store.getAll(),
      _settingsStore.get(),
    ]);

    return _HomeData(
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

  String _nextMonthLabel() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return DateFormat('MMMM').format(nextMonth).toUpperCase(); // e.g. FEBRUARY
  }

  String _currentMonthLabel() {
    final now = DateTime.now();
    final curMonth = DateTime(now.year, now.month, 1);
    return DateFormat('MMMM').format(curMonth).toUpperCase(); // e.g. JANUARY
  }

  List<String> _activeCurrencies(List<Subscription> active) {
    final set = <String>{};
    for (final s in active) {
      set.add(s.currency);
    }
    final list = set.toList()..sort();
    return list;
  }

  Map<String, double> _calculateAnnualTotals(List<Subscription> subs) {
    final totals = <String, double>{};

    final now = DateTime.now();
    final startNextMonth = DateTime(now.year, now.month + 1, 1);
    final endWindow = DateTime(now.year, now.month + 13, 1); // +12 full months

    bool inNextYear(DateTime d) {
      return !d.isBefore(startNextMonth) && d.isBefore(endWindow);
    }

    for (final s in subs) {
      final cur = s.currency;

      // If the next renewal is within the next 12 months, include it
      if (!inNextYear(s.renewalDate)) continue;

      totals.update(
        cur,
        (v) => v + s.price,
        ifAbsent: () => s.price,
      );
    }

    return totals;
  }

  Map<String, double> _calculateNextMonthTotals(List<Subscription> subs) {
    final totals = <String, double>{};

    final now = DateTime.now();
    final startNextMonth = DateTime(now.year, now.month + 1, 1);
    final startMonthAfter = DateTime(now.year, now.month + 2, 1);

    bool inNextMonth(DateTime d) {
      return !d.isBefore(startNextMonth) && d.isBefore(startMonthAfter);
    }

    for (final s in subs) {
      if (!inNextMonth(s.renewalDate)) continue;

      totals.update(
        s.currency,
        (v) => v + s.price,
        ifAbsent: () => s.price,
      );
    }

    return totals;
  }

  Map<String, double> _calculateCurrentMonthRemainingTotals(
      List<Subscription> subs) {
    final totals = <String, double>{};

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startNextMonth = DateTime(now.year, now.month + 1, 1);

    bool inRemainingThisMonth(DateTime d) {
      final dd = DateTime(d.year, d.month, d.day);
      return !dd.isBefore(startToday) && dd.isBefore(startNextMonth);
    }

    for (final s in subs) {
      if (!inRemainingThisMonth(s.renewalDate)) continue;

      totals.update(
        s.currency,
        (v) => v + s.price,
        ifAbsent: () => s.price,
      );
    }

    return totals;
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(today).inDays;
  }

  Widget _warningChips(Subscription s) {
    final renewIn = _daysUntil(s.renewalDate);
    final renewWarn = renewIn >= 0 && renewIn <= 3;

    final int? trialIn = (s.hasFreeTrial && s.freeTrialEnds != null)
        ? _daysUntil(s.freeTrialEnds!)
        : null;
    final trialWarn = trialIn != null && trialIn >= 0 && trialIn <= 3;

    if (!renewWarn && !trialWarn) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: -6,
      alignment: WrapAlignment.end,
      children: [
        if (renewWarn) Chip(label: Text('Renews in ${renewIn}d')),
        if (trialWarn) Chip(label: Text('Trial ends in ${trialIn}d')),
      ],
    );
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

  String _recurrenceLabel(Subscription s) {
    final rec = (s.recurrence ?? 'monthly');
    return rec == 'annual' ? 'annual' : 'monthly';
  }

  String _buildLeftSubtitle(Subscription s, AppSettings st, DateFormat df) {
    final parts = <String>[];

    if (st.showPrice) {
      parts.add('${s.price.toStringAsFixed(2)} ${s.currency}');
    }
    if (st.showRecurrence) {
      parts.add(_recurrenceLabel(s));
    }
    if (st.showRenewalDate) {
      parts.add('renews ${df.format(s.renewalDate)}');
    }

    // If user hides everything, keep a minimal line to avoid an empty subtitle.
    if (parts.isEmpty) return ' ';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'stats') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsPage()),
                );
                await _refresh();
              }
              if (v == 'settings') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
                await _refresh();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'stats', child: Text('Statistics')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_HomeData>(
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

          // totals mode from settings
          final totalsMode = st.homeTotalMode; // 'monthly' or 'annual'
          final monthlyView = st.monthlyTotalView; // 'next' or 'current'

          final Map<String, double> totals = (totalsMode == 'annual')
              ? _calculateAnnualTotals(active)
              : (monthlyView == 'current'
                  ? _calculateCurrentMonthRemainingTotals(active)
                  : _calculateNextMonthTotals(active));

          final currencies = _activeCurrencies(active);

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
                  ? 'Total - ${_currentMonthLabel()} (REMAINING)'
                  : 'Total - ${_nextMonthLabel()}');

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // --- TOTAL CARD (ACTIVE ONLY) ---
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Always show 0.00 <currency> for currencies present in active subscriptions.
                      if (currencies.isEmpty)
                        // No active subscriptions at all — show one line in default currency from settings.
                        Text(
                          '0.00 ${st.defaultCurrency} ${totalsMode == "annual" ? "/ next 12 months" : "/ next month"}',
                          style: const TextStyle(fontSize: 16),
                        )
                      else
                        for (final cur in currencies)
                          Text(
                            '${(totals[cur] ?? 0).toStringAsFixed(2)} $cur',
                            style: const TextStyle(fontSize: 16),
                          ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --- ACTIVE LIST HEADER ---
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Active',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${active.length}'),
                ],
              ),
              const SizedBox(height: 8),

              // --- ACTIVE LIST (SWIPE TO CANCEL) ---
              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No active subscriptions.'),
                )
              else
                ...active.map((s) {
                  final leftSubtitle = _buildLeftSubtitle(s, st, df);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey('active-${s.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.cancel),
                      ),
                      confirmDismiss: (_) async => _confirmCancel(s.name),
                      onDismissed: (_) async {
                        await _store.cancel(s.id);
                        await _refresh();
                      },

                      // overflow-safe layout
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(leftSubtitle),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // RIGHT SIDE (usage + badges) controlled by settings
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 160),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (st.showUsageFrequency)
                                        Text('${s.usagePerWeek}/wk'),
                                      if (st.showBadges) ...[
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: _warningChips(s),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // --- HISTORY SECTION ---
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${canceled.length}'),
                ],
              ),
              const SizedBox(height: 8),

              if (canceled.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No canceled subscriptions yet.'),
                )
              else
                ...canceled.map((s) {
                  final canceledText = (s.canceledAt == null)
                      ? 'Canceled'
                      : 'Canceled on ${df.format(s.canceledAt!)}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.price.toStringAsFixed(2)} ${s.currency} • $canceledText',
                        ),
                        trailing: const Chip(label: Text('Canceled')),
                        onTap: () async {
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
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
