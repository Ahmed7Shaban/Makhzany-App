// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentalItemAdapter extends TypeAdapter<RentalItem> {
  @override
  final int typeId = 3;

  @override
  RentalItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RentalItem(
      itemId: fields[0] as String,
      itemName: fields[1] as String,
      quantity: fields[2] as int,
      priceAtMoment: fields[3] as double,
      startDate: fields[4] as DateTime,
      returnDate: fields[5] as DateTime?,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RentalItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.priceAtMoment)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.returnDate)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
