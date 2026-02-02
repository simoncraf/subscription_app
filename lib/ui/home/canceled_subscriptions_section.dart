import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/subscription.dart';

class CanceledSubscriptionsSection extends StatelessWidget {
  final List<Subscription> canceled;
  final DateFormat dateFormat;
  final Future<void> Function(Subscription subscription) onOpenDetails;

  const CanceledSubscriptionsSection({
    super.key,
    required this.canceled,
    required this.dateFormat,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          for (final s in canceled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    '${s.price.toStringAsFixed(2)} ${s.currency} - ${_canceledText(s)}',
                  ),
                  trailing: const Chip(label: Text('Canceled')),
                  onTap: () => onOpenDetails(s),
                ),
              ),
            ),
      ],
    );
  }

  String _canceledText(Subscription s) {
    if (s.canceledAt == null) return 'Canceled';
    return 'Canceled on ${dateFormat.format(s.canceledAt!)}';
  }
}
