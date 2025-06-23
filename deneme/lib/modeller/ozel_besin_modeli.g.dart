// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ozel_besin_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OzelBesinModeliAdapter extends TypeAdapter<OzelBesinModeli> {
  @override
  final int typeId = 4;

  @override
  OzelBesinModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OzelBesinModeli(
      id: fields[0] as int?,
      kullaniciId: fields[1] as String,
      isim: fields[2] as String,
      yuzGramKalori: fields[3] as double,
      yuzGramProtein: fields[4] as double,
      yuzGramKarbonhidrat: fields[5] as double,
      yuzGramYag: fields[6] as double,
      yuzGramLif: fields[7] as double,
      kategori: fields[8] as String,
      eklenmeTarihi: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OzelBesinModeli obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kullaniciId)
      ..writeByte(2)
      ..write(obj.isim)
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
      ..write(obj.kategori)
      ..writeByte(9)
      ..write(obj.eklenmeTarihi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OzelBesinModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OzelBesinModeli _$OzelBesinModeliFromJson(Map<String, dynamic> json) =>
    OzelBesinModeli(
      id: (json['id'] as num?)?.toInt(),
      kullaniciId: json['kullaniciId'] as String,
      isim: json['isim'] as String,
      yuzGramKalori: (json['yuzGramKalori'] as num).toDouble(),
      yuzGramProtein: (json['yuzGramProtein'] as num?)?.toDouble() ?? 0.0,
      yuzGramKarbonhidrat:
          (json['yuzGramKarbonhidrat'] as num?)?.toDouble() ?? 0.0,
      yuzGramYag: (json['yuzGramYag'] as num?)?.toDouble() ?? 0.0,
      yuzGramLif: (json['yuzGramLif'] as num?)?.toDouble() ?? 0.0,
      kategori: json['kategori'] as String? ?? 'Özel Besin',
      eklenmeTarihi: json['eklenmeTarihi'] == null
          ? null
          : DateTime.parse(json['eklenmeTarihi'] as String),
    );

Map<String, dynamic> _$OzelBesinModeliToJson(OzelBesinModeli instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kullaniciId': instance.kullaniciId,
      'isim': instance.isim,
      'yuzGramKalori': instance.yuzGramKalori,
      'yuzGramProtein': instance.yuzGramProtein,
      'yuzGramKarbonhidrat': instance.yuzGramKarbonhidrat,
      'yuzGramYag': instance.yuzGramYag,
      'yuzGramLif': instance.yuzGramLif,
      'kategori': instance.kategori,
      'eklenmeTarihi': instance.eklenmeTarihi.toIso8601String(),
    };
