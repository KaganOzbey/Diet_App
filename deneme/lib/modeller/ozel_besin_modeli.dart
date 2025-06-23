import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'ozel_besin_modeli.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class OzelBesinModeli extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String kullaniciId;
  
  @HiveField(2)
  final String isim;
  
  @HiveField(3)
  final double yuzGramKalori;
  
  @HiveField(4)
  final double yuzGramProtein;
  
  @HiveField(5)
  final double yuzGramKarbonhidrat;
  
  @HiveField(6)
  final double yuzGramYag;
  
  @HiveField(7)
  final double yuzGramLif;
  
  @HiveField(8)
  final String kategori;
  
  @HiveField(9)
  final DateTime eklenmeTarihi;

  OzelBesinModeli({
    this.id,
    required this.kullaniciId,
    required this.isim,
    required this.yuzGramKalori,
    this.yuzGramProtein = 0.0,
    this.yuzGramKarbonhidrat = 0.0,
    this.yuzGramYag = 0.0,
    this.yuzGramLif = 0.0,
    this.kategori = 'Özel Besin',
    DateTime? eklenmeTarihi,
  }) : eklenmeTarihi = eklenmeTarihi ?? DateTime.now();

  factory OzelBesinModeli.fromJson(Map<String, dynamic> json) =>
      _$OzelBesinModeliFromJson(json);

  Map<String, dynamic> toJson() => _$OzelBesinModeliToJson(this);

  OzelBesinModeli copyWith({
    int? id,
    String? kullaniciId,
    String? isim,
    double? yuzGramKalori,
    double? yuzGramProtein,
    double? yuzGramKarbonhidrat,
    double? yuzGramYag,
    double? yuzGramLif,
    String? kategori,
    DateTime? eklenmeTarihi,
  }) {
    return OzelBesinModeli(
      id: id ?? this.id,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      isim: isim ?? this.isim,
      yuzGramKalori: yuzGramKalori ?? this.yuzGramKalori,
      yuzGramProtein: yuzGramProtein ?? this.yuzGramProtein,
      yuzGramKarbonhidrat: yuzGramKarbonhidrat ?? this.yuzGramKarbonhidrat,
      yuzGramYag: yuzGramYag ?? this.yuzGramYag,
      yuzGramLif: yuzGramLif ?? this.yuzGramLif,
      kategori: kategori ?? this.kategori,
      eklenmeTarihi: eklenmeTarihi ?? this.eklenmeTarihi,
    );
  }
} 