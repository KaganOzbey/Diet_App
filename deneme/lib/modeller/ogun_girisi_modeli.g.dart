// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ogun_girisi_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OgunGirisiModeliAdapter extends TypeAdapter<OgunGirisiModeli> {
  @override
  final int typeId = 2;

  @override
  OgunGirisiModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OgunGirisiModeli(
      id: fields[0] as String,
      kullaniciId: fields[1] as String,
      yemekId: fields[2] as String,
      yemekIsmi: fields[3] as String,
      tuketilenGram: fields[4] as double,
      kalori: fields[5] as double,
      protein: fields[6] as double,
      karbonhidrat: fields[7] as double,
      yag: fields[8] as double,
      ogunTipi: fields[9] as String,
      tuketimTarihi: fields[10] as DateTime,
      kayitTarihi: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OgunGirisiModeli obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kullaniciId)
      ..writeByte(2)
      ..write(obj.yemekId)
      ..writeByte(3)
      ..write(obj.yemekIsmi)
      ..writeByte(4)
      ..write(obj.tuketilenGram)
      ..writeByte(5)
      ..write(obj.kalori)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.karbonhidrat)
      ..writeByte(8)
      ..write(obj.yag)
      ..writeByte(9)
      ..write(obj.ogunTipi)
      ..writeByte(10)
      ..write(obj.tuketimTarihi)
      ..writeByte(11)
      ..write(obj.kayitTarihi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OgunGirisiModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
