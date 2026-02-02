import 'package:flutter/material.dart';

import '../../data/settings_store.dart';

class TotalsCard extends StatelessWidget {
  final String titleText;
  final Map<String, double> totals;
  final List<String> currencies;
  final AppSettings settings;

  const TotalsCard({
    super.key,
    required this.titleText,
    required this.totals,
    required this.currencies,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (currencies.isEmpty)
              Text(
                '0.00 ${settings.defaultCurrency}',
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
    );
  }
}
