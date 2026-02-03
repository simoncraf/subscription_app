import 'package:flutter/material.dart';

import '../../data/currencies.dart';

Future<String?> showCurrencyPicker({
  required BuildContext context,
  required String? selected,
  String title = 'Select currency',
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final all = currencyCodesWithCommon();
      final searchIndex = {
        for (final c in all) c: _normalize(currencySearchText(c)),
      };
      var query = '';

      return StatefulBuilder(
        builder: (context, setState) {
          final normalizedQuery = _normalize(query);
          final filtered = normalizedQuery.isEmpty
              ? all
              : all
                  .where((c) => searchIndex[c]!.contains(normalizedQuery))
                  .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => query = v.trim()),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final code = filtered[index];
                      final isSelected = code == selected;
                      return ListTile(
                        leading: Text(
                          currencyFlag(code),
                          style: const TextStyle(fontSize: 18),
                        ),
                        title: Text(code),
                        trailing: isSelected
                            ? const Icon(Icons.check, size: 18)
                            : null,
                        onTap: () => Navigator.pop(context, code),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class CurrencyPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String labelText;

  const CurrencyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showCurrencyPicker(
          context: context,
          selected: value,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        child: Text('${currencyFlag(value)} $value'),
      ),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
