// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kilo_girisi_modeli.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KiloGirisiModeliAdapter extends TypeAdapter<KiloGirisiModeli> {
  @override
  final int typeId = 5;

  @override
  KiloGirisiModeli read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KiloGirisiModeli(
      id: fields[0] as String,
      kullaniciId: fields[1] as String,
      kilo: fields[2] as double,
      olcumTarihi: fields[3] as DateTime,
      kayitTarihi: fields[4] as DateTime,
      notlar: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KiloGirisiModeli obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kullaniciId)
      ..writeByte(2)
      ..write(obj.kilo)
      ..writeByte(3)
      ..write(obj.olcumTarihi)
      ..writeByte(4)
      ..write(obj.kayitTarihi)
      ..writeByte(5)
      ..write(obj.notlar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KiloGirisiModeliAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KiloGirisiModeli _$KiloGirisiModeliFromJson(Map<String, dynamic> json) =>
    KiloGirisiModeli(
      id: json['id'] as String,
      kullaniciId: json['kullaniciId'] as String,
      kilo: (json['kilo'] as num).toDouble(),
      olcumTarihi: DateTime.parse(json['olcumTarihi'] as String),
      kayitTarihi: DateTime.parse(json['kayitTarihi'] as String),
      notlar: json['notlar'] as String?,
    );

Map<String, dynamic> _$KiloGirisiModeliToJson(KiloGirisiModeli instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kullaniciId': instance.kullaniciId,
      'kilo': instance.kilo,
      'olcumTarihi': instance.olcumTarihi.toIso8601String(),
      'kayitTarihi': instance.kayitTarihi.toIso8601String(),
      'notlar': instance.notlar,
    };
