import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'kilo_girisi_modeli.g.dart';

@HiveType(typeId: 5)
@JsonSerializable()
class KiloGirisiModeli extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String kullaniciId;
  
  @HiveField(2)
  final double kilo; // kg cinsinden
  
  @HiveField(3)
  final DateTime olcumTarihi;
  
  @HiveField(4)
  final DateTime kayitTarihi;
  
  @HiveField(5)
  final String? notlar; // Opsiyonel notlar

  KiloGirisiModeli({
    required this.id,
    required this.kullaniciId,
    required this.kilo,
    required this.olcumTarihi,
    required this.kayitTarihi,
    this.notlar,
  });

  factory KiloGirisiModeli.fromJson(Map<String, dynamic> json) =>
      _$KiloGirisiModeliFromJson(json);

  Map<String, dynamic> toJson() => _$KiloGirisiModeliToJson(this);

  // Kilo değişimi hesaplama
  double kiloFarkiHesapla(double oncekiKilo) {
    return kilo - oncekiKilo;
  }

  // Formatlanmış kilo string'i
  String get formatlananKilo => '${kilo.toStringAsFixed(1)} kg';
  
  // Kilo değişimi string'i
  String kiloFarkiMetni(double oncekiKilo) {
    final fark = kiloFarkiHesapla(oncekiKilo);
    if (fark > 0) {
      return '+${fark.toStringAsFixed(1)} kg';
    } else if (fark < 0) {
      return '${fark.toStringAsFixed(1)} kg';
    } else {
      return 'Değişim yok';
    }
  }

  KiloGirisiModeli copyWith({
    String? id,
    String? kullaniciId,
    double? kilo,
    DateTime? olcumTarihi,
    DateTime? kayitTarihi,
    String? notlar,
  }) {
    return KiloGirisiModeli(
      id: id ?? this.id,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      kilo: kilo ?? this.kilo,
      olcumTarihi: olcumTarihi ?? this.olcumTarihi,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      notlar: notlar ?? this.notlar,
    );
  }
} 