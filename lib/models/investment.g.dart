// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAdapter extends TypeAdapter<Investment> {
  @override
  final int typeId = 1;

  @override
  Investment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Investment(
      title: fields[0] as String,
      type: fields[1] as String,
      investedAmount: fields[2] as double,
      currentValue: fields[3] as double,
      date: fields[4] as DateTime,
      owner: fields[5] as String,
      notes: fields[6] as String,
      importId: fields[7] as String?,
      source: fields[8] == null ? 'manual' : fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Investment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.investedAmount)
      ..writeByte(3)
      ..write(obj.currentValue)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.owner)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.importId)
      ..writeByte(8)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
