import 'package:flutter/material.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';
import 'add_subscription_sheet.dart';
import 'package:intl/intl.dart';

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

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: subs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = subs[i];
              return Dismissible(
                key: ValueKey(s.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete subscription?'),
                          content: Text('Delete "${s.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
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
                      '${s.price.toStringAsFixed(2)} ${s.currency} • renews ${df.format(s.renewalDate)}'
                      '${s.hasFreeTrial && s.freeTrialEnds != null ? '\nTrial ends ${df.format(s.freeTrialEnds!)}' : ''}',
                    ),
                    trailing: Text('${s.usagePerWeek}/wk'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
