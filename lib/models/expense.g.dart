// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      title: fields[0] as String,
      amount: fields[1] as double,
      category: fields[2] as String,
      date: fields[3] as DateTime,
      merchant: fields[4] as String?,
      paymentMethod: fields[5] == null ? 'Unknown' : fields[5] as String,
      source: fields[6] == null ? 'manual' : fields[6] as String,
      person: fields[7] == null ? 'Shared' : fields[7] as String,
      transactionId: fields[8] as String?,
      isCategorized: fields[9] == null ? true : fields[9] as bool,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.merchant)
      ..writeByte(5)
      ..write(obj.paymentMethod)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.person)
      ..writeByte(8)
      ..write(obj.transactionId)
      ..writeByte(9)
      ..write(obj.isCategorized)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
