// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentalTransactionAdapter extends TypeAdapter<RentalTransaction> {
  @override
  final int typeId = 2;

  @override
  RentalTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RentalTransaction(
      id: fields[0] as String,
      tenantId: fields[1] as String,
      tenantName: fields[7] as String,
      startDate: fields[2] as DateTime,
      items: (fields[5] as List).cast<RentalItem>(),
      isActive: fields[4] as bool,
      endDate: fields[3] as DateTime?,
      tenantPhone: fields[8] as String?,
      tenantAddress: fields[9] as String?,
      discountFridays: fields[10] as bool,
      payments: (fields[11] as List?)?.cast<PaymentLog>(),
      invoices: (fields[13] as List?)?.cast<FinancialRecord>(),
      lastSettlementDate: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RentalTransaction obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tenantId)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.tenantName)
      ..writeByte(8)
      ..write(obj.tenantPhone)
      ..writeByte(9)
      ..write(obj.tenantAddress)
      ..writeByte(10)
      ..write(obj.discountFridays)
      ..writeByte(11)
      ..write(obj.payments)
      ..writeByte(12)
      ..write(obj.lastSettlementDate)
      ..writeByte(13)
      ..write(obj.invoices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
