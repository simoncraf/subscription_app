import 'package:flutter/material.dart';

import '../../data/subscription.dart';
import 'home_helpers.dart';

class WarningChips extends StatelessWidget {
  final Subscription subscription;

  const WarningChips({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final renewIn = daysUntil(subscription.renewalDate);
    final renewWarn = renewIn >= 0 && renewIn <= 3;

    final int? trialIn =
        (subscription.hasFreeTrial && subscription.freeTrialEnds != null)
            ? daysUntil(subscription.freeTrialEnds!)
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
}
