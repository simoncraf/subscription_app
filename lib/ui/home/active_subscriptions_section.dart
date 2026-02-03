import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/settings_store.dart';
import '../../data/subscription.dart';
import 'home_helpers.dart';
import 'warning_chips.dart';

class ActiveSubscriptionsSection extends StatelessWidget {
  final List<Subscription> active;
  final AppSettings settings;
  final DateFormat dateFormat;
  final String sortValue;
  final ValueChanged<String> onSortChange;
  final Future<bool> Function(String name) onConfirmCancel;
  final Future<void> Function(Subscription subscription) onCancel;
  final Future<void> Function(Subscription subscription) onOpenDetails;

  const ActiveSubscriptionsSection({
    super.key,
    required this.active,
    required this.settings,
    required this.dateFormat,
    required this.sortValue,
    required this.onSortChange,
    required this.onConfirmCancel,
    required this.onCancel,
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
                'Active',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text('${active.length}'),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort, size: 20),
              initialValue: sortValue,
              onSelected: onSortChange,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'renewal', child: Text('Renewal date')),
                PopupMenuItem(value: 'price_desc', child: Text('Price (high → low)')),
                PopupMenuItem(value: 'alpha', child: Text('Alphabetical')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No active subscriptions.'),
          )
        else
          for (final s in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey('active-${s.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.cancel),
                ),
                confirmDismiss: (_) async => onConfirmCancel(s.name),
                onDismissed: (_) => onCancel(s),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOpenDetails(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                Text(buildLeftSubtitle(s, settings, dateFormat)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (settings.showUsageFrequency)
                                  Text('${s.usagePerWeek}/wk'),
                                if (settings.showBadges) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: WarningChips(subscription: s),
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
            ),
      ],
    );
  }
}
