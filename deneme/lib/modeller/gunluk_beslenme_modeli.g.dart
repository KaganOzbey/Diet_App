// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gunluk_beslenme_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GunlukBeslenmeModeliAdapter extends TypeAdapter<GunlukBeslenmeModeli> {
  @override
  final int typeId = 3;

  @override
  GunlukBeslenmeModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GunlukBeslenmeModeli(
      id: fields[0] as String,
      kullaniciId: fields[1] as String,
      tarih: fields[2] as DateTime,
      toplamKalori: fields[3] as double,
      toplamProtein: fields[4] as double,
      toplamKarbonhidrat: fields[5] as double,
      toplamYag: fields[6] as double,
      toplamLif: fields[7] as double,
      kaloriHedefi: fields[8] as double,
      ogunSayisi: fields[9] as int,
      ogunGirisiIdleri: (fields[10] as List?)?.cast<String>(),
      olusturulmaTarihi: fields[11] as DateTime,
      guncellemeTarihi: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GunlukBeslenmeModeli obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kullaniciId)
      ..writeByte(2)
      ..write(obj.tarih)
      ..writeByte(3)
      ..write(obj.toplamKalori)
      ..writeByte(4)
      ..write(obj.toplamProtein)
      ..writeByte(5)
      ..write(obj.toplamKarbonhidrat)
      ..writeByte(6)
      ..write(obj.toplamYag)
      ..writeByte(7)
      ..write(obj.toplamLif)
      ..writeByte(8)
      ..write(obj.kaloriHedefi)
      ..writeByte(9)
      ..write(obj.ogunSayisi)
      ..writeByte(10)
      ..write(obj.ogunGirisiIdleri)
      ..writeByte(11)
      ..write(obj.olusturulmaTarihi)
      ..writeByte(12)
      ..write(obj.guncellemeTarihi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GunlukBeslenmeModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
