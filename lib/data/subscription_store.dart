import 'package:hive/hive.dart';
import 'subscription.dart';

class SubscriptionStore {
  static const String boxName = 'subscriptions_box';

  Future<Box<Subscription>> _box() async {
    return Hive.openBox<Subscription>(boxName);
  }

  Future<List<Subscription>> getAll() async {
    final box = await _box();
    return box.values.toList(growable: false);
  }

  Future<void> add(Subscription sub) async {
    final box = await _box();
    await box.put(sub.id, sub);
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<void> upsert(Subscription sub) async {
    final box = await _box();
    await box.put(sub.id, sub);
  }

  Future<Subscription?> getById(String id) async {
    final box = await _box();
    return box.get(id);
  }

  Future<void> cancel(String id) async {
    final box = await _box();
    final existing = box.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      isCanceled: true,
      canceledAt: DateTime.now(),
    );

    await box.put(id, updated);
  }

  Future<void> reactivate(String id) async {
    final box = await _box();
    final existing = box.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      isCanceled: false,
      canceledAt: null,
    );

    await box.put(id, updated);
  }
}
