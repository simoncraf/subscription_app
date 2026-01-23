import 'package:hive_flutter/hive_flutter.dart';

class PaymentCardStore {
  static const String _boxName = 'payment_cards';

  Future<Box<String>> _box() async {
    return Hive.openBox<String>(_boxName);
  }

  Future<List<String>> getAll() async {
    final box = await _box();
    final cards = box.values.toList();
    cards.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cards;
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final box = await _box();

    final exists = box.values.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;

    await box.add(trimmed);
  }
}