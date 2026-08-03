// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportHistoryAdapter extends TypeAdapter<ImportHistory> {
  @override
  final int typeId = 6;

  @override
  ImportHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportHistory(
      id: fields[0] as String,
      source: fields[1] as String,
      importedAt: fields[2] as DateTime,
      totalTransactions: fields[3] as int,
      importedExpenses: fields[4] as int,
      reviewedTransactions: fields[5] as int,
      skippedTransactions: fields[6] as int,
      merchantRulesSaved: fields[7] as int,
      importedAmount: fields[8] as double,
      fileName: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ImportHistory obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.source)
      ..writeByte(2)
      ..write(obj.importedAt)
      ..writeByte(3)
      ..write(obj.totalTransactions)
      ..writeByte(4)
      ..write(obj.importedExpenses)
      ..writeByte(5)
      ..write(obj.reviewedTransactions)
      ..writeByte(6)
      ..write(obj.skippedTransactions)
      ..writeByte(7)
      ..write(obj.merchantRulesSaved)
      ..writeByte(8)
      ..write(obj.importedAmount)
      ..writeByte(9)
      ..write(obj.fileName)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
