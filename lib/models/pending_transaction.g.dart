// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingTransactionAdapter extends TypeAdapter<PendingTransaction> {
  @override
  final int typeId = 3;

  @override
  PendingTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingTransaction(
      title: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      merchant: fields[3] as String,
      paymentMethod: fields[4] as String,
      transactionId: fields[5] as String?,
      source: fields[6] as String,
      suggestedCategory: fields[7] as String?,
      suggestedPerson: fields[8] as String?,
      isReviewed: fields[9] as bool,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingTransaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.merchant)
      ..writeByte(4)
      ..write(obj.paymentMethod)
      ..writeByte(5)
      ..write(obj.transactionId)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.suggestedCategory)
      ..writeByte(8)
      ..write(obj.suggestedPerson)
      ..writeByte(9)
      ..write(obj.isReviewed)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
