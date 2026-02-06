// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialRecordAdapter extends TypeAdapter<FinancialRecord> {
  @override
  final int typeId = 5;

  @override
  FinancialRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialRecord(
      amount: fields[0] as double,
      date: fields[1] as DateTime,
      periodStar: fields[2] as DateTime,
      periodEnd: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.periodStar)
      ..writeByte(3)
      ..write(obj.periodEnd)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
