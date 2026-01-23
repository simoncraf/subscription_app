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
}
