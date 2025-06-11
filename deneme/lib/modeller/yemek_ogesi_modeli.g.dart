// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yemek_ogesi_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class YemekOgesiModeliAdapter extends TypeAdapter<YemekOgesiModeli> {
  @override
  final int typeId = 1;

  @override
  YemekOgesiModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YemekOgesiModeli(
      id: fields[0] as String,
      isim: fields[1] as String,
      fdcId: fields[2] as int,
      yuzGramKalori: fields[3] as double,
      yuzGramProtein: fields[4] as double,
      yuzGramKarbonhidrat: fields[5] as double,
      yuzGramYag: fields[6] as double,
      yuzGramLif: fields[7] as double,
      yuzGramSeker: fields[8] as double,
      kategori: fields[9] as String,
      eklenmeTarihi: fields[10] as DateTime,
      favoriMi: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, YemekOgesiModeli obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isim)
      ..writeByte(2)
      ..write(obj.fdcId)
      ..writeByte(3)
      ..write(obj.yuzGramKalori)
      ..writeByte(4)
      ..write(obj.yuzGramProtein)
      ..writeByte(5)
      ..write(obj.yuzGramKarbonhidrat)
      ..writeByte(6)
      ..write(obj.yuzGramYag)
      ..writeByte(7)
      ..write(obj.yuzGramLif)
      ..writeByte(8)
      ..write(obj.yuzGramSeker)
      ..writeByte(9)
      ..write(obj.kategori)
      ..writeByte(10)
      ..write(obj.eklenmeTarihi)
      ..writeByte(11)
      ..write(obj.favoriMi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YemekOgesiModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
