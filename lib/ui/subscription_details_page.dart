import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';
import 'add_subscription_sheet.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailsPage({super.key, required this.subscriptionId});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  final _store = SubscriptionStore();
  final _df = DateFormat('yyyy-MM-dd');

  Future<Subscription?> _load() async {
    return _store.getById(widget.subscriptionId);
  }

  Future<void> _edit(Subscription s) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddSubscriptionSheet(initial: s),
    );

    if (updated == true) {
      setState(() {}); // reload details
    }
  }

  Future<void> _cancelSubscription(Subscription s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel subscription'),
        content: Text(
          'Cancel "${s.name}"?\n\n'
          'It will be moved to history (not deleted).',
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

    if (confirmed != true) return;

    await _store.cancel(s.id);

    if (!mounted) return;
    Navigator.pop(context, true); // back to home to refresh lists
  }

  Future<void> _reactivateSubscription(Subscription s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivate subscription'),
        content: Text(
          'Reactivate "${s.name}"?\n\n'
          'It will return to Active subscriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _store.reactivate(s.id);

    if (!mounted) return;
    Navigator.pop(context, true); // back to home to refresh lists
  }

  Future<void> _deletePermanently(Subscription s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          'This will permanently remove "${s.name}" from your phone, including History.\n\n'
          'If you only want to stop tracking it, use "Cancel subscription" instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _store.delete(s.id);

    if (!mounted) return;
    Navigator.pop(context, true); // return to list so it refreshes
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          FutureBuilder<Subscription?>(
            future: _load(),
            builder: (context, snapshot) {
              final sub = snapshot.data;
              if (sub == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _edit(sub);
                  if (v == 'delete') _deletePermanently(sub);
                },
                itemBuilder: (_) => [
                  if (!sub.isCanceled)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete permanently')),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Subscription?>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final s = snapshot.data;
          if (s == null) {
            return const Center(child: Text('Subscription not found.'));
          }

          final costPerUse =
              (s.usagePerWeek <= 0) ? null : (s.price / s.usagePerWeek);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                s.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Divider(),
              _row('Status', s.isCanceled ? 'Canceled' : 'Active'),
              if (s.isCanceled && s.canceledAt != null)
                _row('Canceled at', _df.format(s.canceledAt!)),
              _row('Price', '${s.price.toStringAsFixed(2)} ${s.currency}'),
              _row('Renewal date', _df.format(s.renewalDate)),
              _row('Free trial', s.hasFreeTrial ? 'Yes' : 'No'),
              if (s.hasFreeTrial && s.freeTrialEnds != null)
                _row('Trial ends', _df.format(s.freeTrialEnds!)),
              _row('Payment card', s.paymentCardLabel),
              _row('Usage per week', '${s.usagePerWeek}'),
              _row(
                'Cost per weekly use',
                costPerUse == null
                    ? 'N/A'
                    : '${costPerUse.toStringAsFixed(2)} ${s.currency}',
              ),
              _row('Reminders', s.remindersEnabled ? 'Enabled' : 'Disabled'),
              if (s.remindersEnabled)
                _row('Reminder', '${s.reminderDaysBefore} day(s) before'),
              const SizedBox(height: 32),
              if (!s.isCanceled)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _cancelSubscription(s),
                  child: const Text('Cancel subscription'),
                )
              else
                FilledButton(
                  onPressed: () => _reactivateSubscription(s),
                  child: const Text('Reactivate subscription'),
                ),
            ],
          );
        },
      ),
    );
  }
}
