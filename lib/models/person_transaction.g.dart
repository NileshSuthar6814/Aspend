// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonTransactionAdapter extends TypeAdapter<PersonTransaction> {
  @override
  final int typeId = 4;

  @override
  PersonTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonTransaction(
      personName: fields[0] as String,
      amount: fields[1] as double,
      note: fields[2] as String,
      date: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PersonTransaction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.personName)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
