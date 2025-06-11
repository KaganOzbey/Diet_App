// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kullanici_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KullaniciModeliAdapter extends TypeAdapter<KullaniciModeli> {
  @override
  final int typeId = 0;

  @override
  KullaniciModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KullaniciModeli(
      email: fields[1] as String,
      isim: fields[2] as String,
      boy: fields[3] as double,
      kilo: fields[4] as double,
      yas: fields[5] as int,
      erkekMi: fields[6] as bool,
      aktiviteSeviyesi: fields[9] as int,
      olusturulmaTarihi: fields[10] as DateTime?,
      guncellemeTarihi: fields[11] as DateTime?,
      emailDogrulandiMi: fields[12] as bool,
    )
      ..id = fields[0] as String
      ..bmr = fields[7] as double
      ..gunlukKaloriHedefi = fields[8] as double;
  }

  @override
  void write(BinaryWriter writer, KullaniciModeli obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.isim)
      ..writeByte(3)
      ..write(obj.boy)
      ..writeByte(4)
      ..write(obj.kilo)
      ..writeByte(5)
      ..write(obj.yas)
      ..writeByte(6)
      ..write(obj.erkekMi)
      ..writeByte(7)
      ..write(obj.bmr)
      ..writeByte(8)
      ..write(obj.gunlukKaloriHedefi)
      ..writeByte(9)
      ..write(obj.aktiviteSeviyesi)
      ..writeByte(10)
      ..write(obj.olusturulmaTarihi)
      ..writeByte(11)
      ..write(obj.guncellemeTarihi)
      ..writeByte(12)
      ..write(obj.emailDogrulandiMi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KullaniciModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
