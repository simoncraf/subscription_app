import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/subscription.dart';
import '../data/subscription_store.dart';
import 'add_subscription_sheet.dart';
import 'subscription_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = SubscriptionStore();
  late Future<List<Subscription>> _subsFuture;

  @override
  void initState() {
    super.initState();
    _subsFuture = _store.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _subsFuture = _store.getAll();
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

  Map<String, double> _calculateTotals(List<Subscription> subs) {
    final Map<String, double> totals = {};
    for (final s in subs) {
      totals.update(
        s.currency,
        (value) => value + s.price,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Subscription>>(
        future: _subsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final subs = snapshot.data ?? const <Subscription>[];

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
          final totals = _calculateTotals(active);

          active.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
          canceled.sort((a, b) {
            final at = a.canceledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.canceledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });

          final df = DateFormat('yyyy-MM-dd');

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // --- TOTAL CARD (ACTIVE ONLY) ---
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total (active)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (totals.isEmpty)
                        const Text('No active subscriptions.')
                      else
                        for (final entry in totals.entries)
                          Text(
                            '${entry.value.toStringAsFixed(2)} ${entry.key}',
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

                      // ✅ OVERFLOW FIX: replace ListTile with custom layout
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
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${s.price.toStringAsFixed(2)} ${s.currency} • renews ${df.format(s.renewalDate)}',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // RIGHT
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${s.usagePerWeek}/wk'),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: _warningChips(s),
                                      ),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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