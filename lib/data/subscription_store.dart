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

  Future<List<Subscription>> getAllNormalized() async {
    final subs = await getAll();
    if (subs.isEmpty) return subs;

    final today = _dateOnly(DateTime.now());
    final updates = <Subscription>[];

    final normalized = subs.map((s) {
      if (s.isCanceled) return s;

      final next = (s.recurrenceEffective == 'annual')
          ? _nextAnnualOccurrence(s.renewalDate, today)
          : _nextMonthlyOccurrence(s.renewalDate, today);

      if (_dateOnly(s.renewalDate).isAtSameMomentAs(next)) return s;

      final updated = s.copyWith(renewalDate: next);
      updates.add(updated);
      return updated;
    }).toList(growable: false);

    if (updates.isNotEmpty) {
      final box = await _box();
      for (final u in updates) {
        await box.put(u.id, u);
      }
    }

    return normalized;
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
    final sub = box.get(id);
    if (sub == null) return null;
    if (sub.isCanceled) return sub;

    final today = _dateOnly(DateTime.now());
    final next = (sub.recurrenceEffective == 'annual')
        ? _nextAnnualOccurrence(sub.renewalDate, today)
        : _nextMonthlyOccurrence(sub.renewalDate, today);

    if (_dateOnly(sub.renewalDate).isAtSameMomentAs(next)) return sub;

    final updated = sub.copyWith(renewalDate: next);
    await box.put(updated.id, updated);
    return updated;
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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _nextMonthlyOccurrence(DateTime renewalDate, DateTime from) {
    final targetDay = renewalDate.day;
    var y = from.year;
    var m = from.month;

    DateTime candidate() {
      final lastDay = DateTime(y, m + 1, 0).day;
      final day = targetDay > lastDay ? lastDay : targetDay;
      return DateTime(y, m, day);
    }

    final c = candidate();
    if (!c.isBefore(_dateOnly(from))) return c;

    final next = DateTime(from.year, from.month + 1, 1);
    y = next.year;
    m = next.month;
    return candidate();
  }

  DateTime _nextAnnualOccurrence(DateTime renewalDate, DateTime from) {
    final targetDay = renewalDate.day;
    final targetMonth = renewalDate.month;
    final y = from.year;

    DateTime candidate(int year) {
      final lastDay = DateTime(year, targetMonth + 1, 0).day;
      final day = targetDay > lastDay ? lastDay : targetDay;
      return DateTime(year, targetMonth, day);
    }

    final c = candidate(y);
    if (!c.isBefore(_dateOnly(from))) return c;
    return candidate(y + 1);
  }
}
