import 'package:flutter/material.dart';

import '../widgets/currency_picker.dart';

class CurrencySelectorRow extends StatelessWidget {
  final List<String> currencies;
  final String selected;
  final ValueChanged<String> onChanged;

  const CurrencySelectorRow({
    super.key,
    required this.currencies,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Currency',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 180,
          child: CurrencyPickerField(
            value: selected,
            labelText: 'Currency',
            options: currencies,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
