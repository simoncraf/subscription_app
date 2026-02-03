import '../../data/subscription.dart';

int daysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  return d.difference(today).inDays;
}

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months, 1);

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Returns next occurrence of a renewal date on/after `from` for monthly recurrence.
/// We keep it simple: use the day-of-month from the stored renewalDate.
DateTime nextMonthlyOccurrence(DateTime renewalDate, DateTime from) {
  final targetDay = renewalDate.day;
  var y = from.year;
  var m = from.month;

  DateTime candidate() {
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = targetDay > lastDay ? lastDay : targetDay;
    return DateTime(y, m, day);
  }

  var c = candidate();
  if (!c.isBefore(DateTime(from.year, from.month, from.day))) return c;

  final next = DateTime(from.year, from.month + 1, 1);
  y = next.year;
  m = next.month;
  return candidate();
}

/// Returns a 6-month projection for a given currency, as a list of (monthStart -> total).
/// - monthly subscriptions contribute if they renew in that month
/// - annual subscriptions contribute if their renewalDate month matches
Map<DateTime, double> projectNext6Months({
  required List<Subscription> active,
  required String currency,
}) {
  final now = DateTime.now();
  final start = startOfMonth(DateTime(now.year, now.month + 1, 1));
  final months = List.generate(6, (i) => addMonths(start, i));

  final totals = {for (final m in months) m: 0.0};

  for (final s in active.where((x) => x.currency == currency)) {
    final rec = (s.recurrence ?? 'monthly');

    if (rec == 'annual') {
      for (final m in months) {
        if (isSameMonth(s.renewalDate, m)) {
          totals[m] = (totals[m] ?? 0) + s.price;
        }
      }
    } else {
      for (final m in months) {
        final occ = nextMonthlyOccurrence(s.renewalDate, m);
        if (isSameMonth(occ, m)) {
          totals[m] = (totals[m] ?? 0) + s.price;
        }
      }
    }
  }

  return totals;
}

/// Returns a 4-month projection including the current month.
Map<DateTime, double> projectCurrentAndNext3Months({
  required List<Subscription> active,
  required String currency,
}) {
  final now = DateTime.now();
  final start = startOfMonth(DateTime(now.year, now.month, 1));
  final months = List.generate(4, (i) => addMonths(start, i));

  final totals = {for (final m in months) m: 0.0};

  for (final s in active.where((x) => x.currency == currency)) {
    final rec = (s.recurrence ?? 'monthly');

    if (rec == 'annual') {
      for (final m in months) {
        if (isSameMonth(s.renewalDate, m)) {
          totals[m] = (totals[m] ?? 0) + s.price;
        }
      }
    } else {
      for (final m in months) {
        final occ = nextMonthlyOccurrence(s.renewalDate, m);
        if (isSameMonth(occ, m)) {
          totals[m] = (totals[m] ?? 0) + s.price;
        }
      }
    }
  }

  return totals;
}

List<int> buildUpcomingBuckets({
  required List<Subscription> active,
  required String currency,
  int maxDays = 30,
}) {
  final upcoming = active
      .where((s) => s.currency == currency)
      .map((s) => daysUntil(s.renewalDate))
      .where((d) => d >= 0 && d <= maxDays)
      .toList();

  final buckets = [0, 0, 0, 0];
  for (final d in upcoming) {
    if (d <= 6) {
      buckets[0]++;
    } else if (d <= 13) {
      buckets[1]++;
    } else if (d <= 20) {
      buckets[2]++;
    } else {
      buckets[3]++;
    }
  }

  return buckets;
}
