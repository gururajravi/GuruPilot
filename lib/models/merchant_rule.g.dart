// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MerchantRuleAdapter extends TypeAdapter<MerchantRule> {
  @override
  final int typeId = 2;

  @override
  MerchantRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MerchantRule(
      merchantName: fields[0] as String,
      category: fields[1] as String,
      person: fields[2] as String,
      paymentMethod: fields[3] as String,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MerchantRule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.merchantName)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.person)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
