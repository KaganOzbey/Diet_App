// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitamin_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VitaminModeliAdapter extends TypeAdapter<VitaminModeli> {
  @override
  final int typeId = 6;

  @override
  VitaminModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VitaminModeli(
      id: fields[0] as String,
      vitaminAdi: fields[1] as String,
      gunlukHedef: fields[2] as double,
      alinankMiktar: fields[3] as double,
      tarih: fields[4] as DateTime,
      kullaniciId: fields[5] as String,
      birim: fields[6] as String,
      kaynak: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VitaminModeli obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vitaminAdi)
      ..writeByte(2)
      ..write(obj.gunlukHedef)
      ..writeByte(3)
      ..write(obj.alinankMiktar)
      ..writeByte(4)
      ..write(obj.tarih)
      ..writeByte(5)
      ..write(obj.kullaniciId)
      ..writeByte(6)
      ..write(obj.birim)
      ..writeByte(7)
      ..write(obj.kaynak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VitaminModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
