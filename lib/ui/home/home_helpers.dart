import 'package:intl/intl.dart';

import '../../data/subscription.dart';
import '../../data/settings_store.dart';

String nextMonthLabel() {
  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  return DateFormat('MMMM').format(nextMonth).toUpperCase();
}

String currentMonthLabel() {
  final now = DateTime.now();
  final curMonth = DateTime(now.year, now.month, 1);
  return DateFormat('MMMM').format(curMonth).toUpperCase();
}

List<String> activeCurrencies(List<Subscription> active) {
  final set = <String>{};
  for (final s in active) {
    set.add(s.currency);
  }
  final list = set.toList()..sort();
  return list;
}

Map<String, double> calculateAnnualTotals(List<Subscription> subs) {
  final totals = <String, double>{};

  final now = DateTime.now();
  final startNextMonth = DateTime(now.year, now.month + 1, 1);
  final endWindow = DateTime(now.year, now.month + 13, 1);

  bool inNextYear(DateTime d) {
    return !d.isBefore(startNextMonth) && d.isBefore(endWindow);
  }

  for (final s in subs) {
    if (!inNextYear(s.renewalDate)) continue;
    totals.update(s.currency, (v) => v + s.price, ifAbsent: () => s.price);
  }

  return totals;
}

Map<String, double> calculateNextMonthTotals(List<Subscription> subs) {
  final totals = <String, double>{};

  final now = DateTime.now();
  final startNextMonth = DateTime(now.year, now.month + 1, 1);
  final startMonthAfter = DateTime(now.year, now.month + 2, 1);

  bool inNextMonth(DateTime d) {
    return !d.isBefore(startNextMonth) && d.isBefore(startMonthAfter);
  }

  for (final s in subs) {
    if (!inNextMonth(s.renewalDate)) continue;
    totals.update(s.currency, (v) => v + s.price, ifAbsent: () => s.price);
  }

  return totals;
}

Map<String, double> calculateCurrentMonthRemainingTotals(
    List<Subscription> subs) {
  final totals = <String, double>{};

  final now = DateTime.now();
  final startToday = DateTime(now.year, now.month, now.day);
  final startNextMonth = DateTime(now.year, now.month + 1, 1);

  bool inRemainingThisMonth(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(startToday) && dd.isBefore(startNextMonth);
  }

  for (final s in subs) {
    if (!inRemainingThisMonth(s.renewalDate)) continue;
    totals.update(s.currency, (v) => v + s.price, ifAbsent: () => s.price);
  }

  return totals;
}

int daysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  return d.difference(today).inDays;
}

String recurrenceLabel(Subscription s) {
  final rec = (s.recurrence ?? 'monthly');
  return rec == 'annual' ? 'annual' : 'monthly';
}

String buildLeftSubtitle(Subscription s, AppSettings st, DateFormat df) {
  final parts = <String>[];

  if (st.showPrice) {
    parts.add('${s.price.toStringAsFixed(2)} ${s.currency}');
  }
  if (st.showRecurrence) {
    parts.add(recurrenceLabel(s));
  }
  if (st.showRenewalDate) {
    parts.add('renews ${df.format(s.renewalDate)}');
  }

  if (parts.isEmpty) return ' ';
  return parts.join(' - ');
}
