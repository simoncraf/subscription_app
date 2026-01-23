// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 1;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      currency: fields[3] as String,
      renewalDate: fields[4] as DateTime,
      hasFreeTrial: fields[5] as bool,
      freeTrialEnds: fields[6] as DateTime?,
      paymentCardLabel: fields[7] as String,
      usagePerWeek: fields[8] as int,
      remindersEnabled: fields[9] as bool,
      reminderDaysBefore: fields[10] as int,
      isCanceled: fields[11] as bool,
      canceledAt: fields[12] as DateTime?,
      recurrence: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.renewalDate)
      ..writeByte(5)
      ..write(obj.hasFreeTrial)
      ..writeByte(6)
      ..write(obj.freeTrialEnds)
      ..writeByte(7)
      ..write(obj.paymentCardLabel)
      ..writeByte(8)
      ..write(obj.usagePerWeek)
      ..writeByte(9)
      ..write(obj.remindersEnabled)
      ..writeByte(10)
      ..write(obj.reminderDaysBefore)
      ..writeByte(11)
      ..write(obj.isCanceled)
      ..writeByte(12)
      ..write(obj.canceledAt)
      ..writeByte(13)
      ..write(obj.recurrence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
