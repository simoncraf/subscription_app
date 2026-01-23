import 'package:flutter/material.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';
import 'add_subscription_sheet.dart';
import 'package:intl/intl.dart';

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
          final subs = snapshot.data ?? const <Subscription>[];

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subs.isEmpty) {
            return const Center(
              child: Text('No subscriptions yet.\nTap + to add one.',
                  textAlign: TextAlign.center),
            );
          }

          final df = DateFormat('yyyy-MM-dd');

          final totals = _calculateTotals(subs);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // --- TOTAL CARD ---
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total subscriptions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
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

              // --- SUBSCRIPTION LIST ---
              ...subs.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: ValueKey(s.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete subscription?'),
                              content: Text('Delete "${s.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) async {
                      await _store.delete(s.id);
                      await _refresh();
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.price.toStringAsFixed(2)} ${s.currency}',
                        ),
                        trailing: Text('${s.usagePerWeek}/wk'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubscriptionDetailsPage(subscriptionId: s.id),
                            ),
                          );
                          await _refresh();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
