import 'package:flutter/material.dart';

class StatisticsNotes extends StatelessWidget {
  const StatisticsNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Notes:\n'
      '* Charts are shown per currency to avoid mixing values.\n'
      '* Projection assumes your stored renewalDate is the next renewal date.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
