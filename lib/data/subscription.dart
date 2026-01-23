import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 1)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String currency; // keep simple: "EUR", "PLN", etc.

  @HiveField(4)
  final DateTime renewalDate;

  @HiveField(5)
  final bool hasFreeTrial;

  @HiveField(6)
  final DateTime? freeTrialEnds;

  @HiveField(7)
  final String paymentCardLabel; // e.g. "Revolut", "Visa **** 1234"

  @HiveField(8)
  final int usagePerWeek; // integer for simplicity

  @HiveField(9)
  final bool remindersEnabled;

  @HiveField(10)
  final int reminderDaysBefore; // e.g. 1, 3, 7

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.renewalDate,
    required this.hasFreeTrial,
    required this.freeTrialEnds,
    required this.paymentCardLabel,
    required this.usagePerWeek,
    required this.remindersEnabled,
    required this.reminderDaysBefore,
  });

  Subscription copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    DateTime? renewalDate,
    bool? hasFreeTrial,
    DateTime? freeTrialEnds,
    String? paymentCardLabel,
    int? usagePerWeek,
    bool? remindersEnabled,
    int? reminderDaysBefore,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      renewalDate: renewalDate ?? this.renewalDate,
      hasFreeTrial: hasFreeTrial ?? this.hasFreeTrial,
      freeTrialEnds: freeTrialEnds ?? this.freeTrialEnds,
      paymentCardLabel: paymentCardLabel ?? this.paymentCardLabel,
      usagePerWeek: usagePerWeek ?? this.usagePerWeek,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }
}