// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviewed_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewedTransactionAdapter extends TypeAdapter<ReviewedTransaction> {
  @override
  final int typeId = 5;

  @override
  ReviewedTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewedTransaction(
      transactionId: fields[0] as String,
      transactionType: fields[1] as String,
      merchant: fields[2] as String,
      amount: fields[3] as double,
      transactionDate: fields[4] as DateTime,
      reviewedAt: fields[5] as DateTime,
      source: fields[6] as String,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewedTransaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.transactionId)
      ..writeByte(1)
      ..write(obj.transactionType)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.transactionDate)
      ..writeByte(5)
      ..write(obj.reviewedAt)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewedTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
